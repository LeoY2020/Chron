using Chron.Controls;
using Chron.Services;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;
using Windows.UI.Text;

namespace Chron.Views;

/// <summary>Countdown screen. Five styles: Ring, Sector, Dial, Plain, Immersive.</summary>
public sealed class CountdownPage : ClockPageBase
{
    private const double D = 320;
    private const double Cx = D / 2;
    private const double Cy = D / 2;
    private const double RingRadius = 130;
    private static readonly string[] Names = { "Ring", "Sector", "Dial", "Plain", "Immersive" };

    private TimeSpan _total;
    private TimeSpan _remaining;
    private bool _running;
    private long _lastTicks;

    private readonly DispatcherQueueTimer _timer;
    private readonly Grid _wheelHost;
    private readonly DurationWheel _wheel = new();
    private readonly FontIcon _playIcon;
    private readonly Button _playButton;
    private readonly Button _resetButton;
    private bool _wheelOpen;

    private TextBlock? _digits;
    private Path? _arc;
    private Path? _sector;
    private RotateTransform? _handRotation;
    private Rectangle? _hairline;
    private Grid? _hairlineHost;

    public CountdownPage()
    {
        var seconds = AppServices.Settings.CountdownSeconds;
        if (seconds <= 0)
            seconds = 300;
        _total = TimeSpan.FromSeconds(seconds);
        _remaining = _total;
        Ink = Palette.FromArgb(AppServices.Settings.CountdownInk);
        RingThickness = AppServices.Settings.RingThickness;

        _playIcon = new FontIcon
        {
            Glyph = "\uE768",
            FontSize = 16,
            FontFamily = new FontFamily("Segoe Fluent Icons"),
            Foreground = new SolidColorBrush(Palette.InkDim),
        };
        _playButton = MakeButton(_playIcon, ToggleRunning);
        _resetButton = MakeButton(new FontIcon
        {
            Glyph = "\uE72C",
            FontSize = 16,
            FontFamily = new FontFamily("Segoe Fluent Icons"),
            Foreground = new SolidColorBrush(Palette.InkDim),
        }, Reset);

        var controls = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 18,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0, 0, 0, 44),
        };
        controls.Children.Add(_playButton);
        controls.Children.Add(_resetButton);
        OverlayLayer.Children.Add(controls);

        _wheelHost = BuildWheelHost();
        Children.Add(_wheelHost);

        _timer = DispatcherQueue.CreateTimer();
        _timer.Interval = TimeSpan.FromMilliseconds(100);
        _timer.IsRepeating = true;
        _timer.Tick += OnTimerTick;

        InitializeStyle(AppServices.Settings.CountdownStyle);
    }

    protected override int StyleCount => 5;
    protected override bool SupportsThickness => true;

    protected override string StyleName(int index) => Names[index];

    public void PrimaryAction() => ToggleRunning();

    protected override void OnStylePersisted(int index)
    {
        AppServices.Settings.CountdownStyle = index;
        AppServices.Settings.Save();
    }

    protected override void OnOptionsPersisted()
    {
        AppServices.Settings.CountdownInk = Palette.ToArgb(Ink);
        AppServices.Settings.RingThickness = RingThickness;
        AppServices.Settings.Save();
    }

    protected override void OnStageResized()
    {
        if (StyleIndex == 1)
            Redraw();
        if (StyleIndex == 3 && _digits is not null)
            _digits.FontSize = PlainFontSize();
        UpdateVisuals();
    }

    protected override UIElement CreateStyleVisual(int index)
    {
        _digits = null;
        _arc = null;
        _sector = null;
        _handRotation = null;
        _hairline = null;
        _hairlineHost = null;

        var visual = index switch
        {
            0 => BuildRing(),
            1 => BuildSector(),
            2 => BuildDial(),
            3 => BuildPlain(),
            _ => BuildImmersive(),
        };
        UpdateVisuals();
        return visual;
    }

    private UIElement BuildRing()
    {
        var design = new Grid { Width = D, Height = D };
        design.Children.Add(new Ellipse
        {
            Width = RingRadius * 2,
            Height = RingRadius * 2,
            Stroke = new SolidColorBrush(Color.FromArgb(48, 255, 255, 255)),
            StrokeThickness = RingThickness,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        });

        _arc = new Path
        {
            Width = D,
            Height = D,
            Stretch = Stretch.None,
            Stroke = new SolidColorBrush(Ink),
            StrokeThickness = RingThickness,
            StrokeStartLineCap = PenLineCap.Round,
            StrokeEndLineCap = PenLineCap.Round,
        };
        design.Children.Add(_arc);

        _digits = Typo.Digits(Format(_remaining), 56, Ink);
        AttachDigitTap(_digits, OpenWheel);
        design.Children.Add(_digits);

        return new Viewbox
        {
            Child = design,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(50),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
    }

    private UIElement BuildSector()
    {
        var w = Math.Max(1, Stage.ActualWidth);
        var h = Math.Max(1, Stage.ActualHeight);

        var root = new Grid { Width = w, Height = h };

        _sector = new Path { Width = w, Height = h, Stretch = Stretch.None };
        var gradient = new LinearGradientBrush { StartPoint = new Point(0, 0), EndPoint = new Point(1, 1) };
        gradient.GradientStops.Add(new GradientStop { Color = Palette.Amber, Offset = 0 });
        gradient.GradientStops.Add(new GradientStop { Color = Palette.OrangeDeep, Offset = 1 });
        _sector.Fill = gradient;
        root.Children.Add(_sector);

        _digits = Typo.Digits(Format(_remaining), 64, Ink, FontWeights.SemiBold);
        AttachDigitTap(_digits, OpenWheel);
        root.Children.Add(_digits);

        return root;
    }

    private UIElement BuildDial()
    {
        var design = new Canvas { Width = D, Height = D };
        design.Children.Add(new Ellipse
        {
            Width = RingRadius * 2,
            Height = RingRadius * 2,
            Stroke = new SolidColorBrush(Color.FromArgb(40, 255, 255, 255)),
            StrokeThickness = 1.4,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(D / 2 - RingRadius, D / 2 - RingRadius, 0, 0),
        });

        for (var i = 0; i < 12; i++)
        {
            var angle = i * 30 * Math.PI / 180.0;
            var dot = new Ellipse
            {
                Width = 4,
                Height = 4,
                Fill = new SolidColorBrush(Color.FromArgb(70, 255, 255, 255)),
            };
            Canvas.SetLeft(dot, Cx + RingRadius * Math.Sin(angle) - 2);
            Canvas.SetTop(dot, Cy - RingRadius * Math.Cos(angle) - 2);
            design.Children.Add(dot);
        }

        var rotation = new RotateTransform { CenterX = 1.5, CenterY = RingRadius };
        _handRotation = rotation;
        var hand = new Rectangle
        {
            Width = 3,
            Height = RingRadius,
            RadiusX = 1.5,
            RadiusY = 1.5,
            Fill = new SolidColorBrush(Ink),
            RenderTransform = rotation,
        };
        Canvas.SetLeft(hand, Cx - 1.5);
        Canvas.SetTop(hand, Cy - RingRadius);
        design.Children.Add(hand);

        var overlay = new Grid { Width = D, Height = D };
        _digits = Typo.Digits(Format(_remaining), 54, Ink);
        AttachDigitTap(_digits, OpenWheel);
        overlay.Children.Add(_digits);

        var root = new Grid { Width = D, Height = D };
        root.Children.Add(design);
        root.Children.Add(overlay);
        return new Viewbox
        {
            Child = root,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(56),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
    }

    private UIElement BuildPlain()
    {
        var root = new Grid();
        _digits = Typo.Digits(Format(_remaining), PlainFontSize(), Ink);
        AttachDigitTap(_digits, OpenWheel);
        root.Children.Add(_digits);

        _hairlineHost = new Grid
        {
            Height = 2,
            Width = 180,
            CornerRadius = new CornerRadius(1),
            Background = new SolidColorBrush(Color.FromArgb(30, 255, 255, 255)),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0, 0, 0, 130),
        };
        _hairline = new Rectangle
        {
            Height = 2,
            RadiusX = 1,
            RadiusY = 1,
            HorizontalAlignment = HorizontalAlignment.Left,
            Fill = new SolidColorBrush(Ink),
        };
        _hairlineHost.Children.Add(_hairline);
        root.Children.Add(_hairlineHost);
        return root;
    }

    private UIElement BuildImmersive()
    {
        _digits = Typo.Digits(Format(_remaining), 220, Ink, FontWeights.SemiBold);
        AttachDigitTap(_digits, OpenWheel);
        return new Viewbox
        {
            Child = _digits,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(28, 64, 28, 64),
        };
    }

    private double PlainFontSize() =>
        Math.Max(48, Math.Min(Math.Max(1, Stage.ActualWidth) / 4.2, Math.Max(1, Stage.ActualHeight) * 0.30));

    private void UpdateVisuals()
    {
        var progress = _total <= TimeSpan.Zero ? 0 : 1 - _remaining.TotalSeconds / _total.TotalSeconds;
        progress = Math.Clamp(progress, 0, 1);

        if (_digits is not null)
            _digits.Text = Format(_remaining);

        if (_arc is not null)
            _arc.Data = Geo.Arc(Cx, Cy, RingRadius, progress * 360);

        if (_sector is not null)
        {
            var w = Math.Max(1, Stage.ActualWidth);
            var h = Math.Max(1, Stage.ActualHeight);
            _sector.Width = w;
            _sector.Height = h;
            var radius = Math.Sqrt(w * w + h * h) / 2 * 1.02;
            _sector.Data = Geo.Sector(w / 2, h / 2, radius, progress * 360);
        }

        if (_handRotation is not null)
            _handRotation.Angle = progress * 360;

        if (_hairline is not null && _hairlineHost is not null)
            _hairline.Width = _hairlineHost.ActualWidth * progress;
    }

    private void OnTimerTick(DispatcherQueueTimer sender, object args)
    {
        var now = Environment.TickCount64;
        var elapsed = TimeSpan.FromMilliseconds(now - _lastTicks);
        _lastTicks = now;
        if (!_running)
            return;

        _remaining -= elapsed;
        if (_remaining <= TimeSpan.Zero)
        {
            _remaining = TimeSpan.Zero;
            _running = false;
            _timer.Stop();
            UpdatePlayIcon();
            UpdateVisuals();
            Feedback.Heavy();
            if (_digits is not null)
                Motion.Pulse(_digits, 0.94f, 260);
            return;
        }
        UpdateVisuals();
    }

    private void ToggleRunning()
    {
        if (_wheelOpen)
            CloseWheel();
        if (_remaining <= TimeSpan.Zero)
            _remaining = _total;
        _running = !_running;
        if (_running)
        {
            _lastTicks = Environment.TickCount64;
            _timer.Start();
        }
        else
        {
            _timer.Stop();
        }
        UpdatePlayIcon();
        Feedback.Medium();
        Motion.Pulse(_playButton);
    }

    private void Reset()
    {
        _running = false;
        _timer.Stop();
        _remaining = _total;
        UpdatePlayIcon();
        UpdateVisuals();
        Feedback.Light();
        Motion.Pulse(_resetButton);
    }

    private void UpdatePlayIcon() => _playIcon.Glyph = _running ? "\uE769" : "\uE768";

    private Grid BuildWheelHost()
    {
        var host = new Grid
        {
            Visibility = Visibility.Collapsed,
            Background = new SolidColorBrush(Color.FromArgb(150, 0, 0, 0)),
        };
        var card = new Border
        {
            Background = new SolidColorBrush(Color.FromArgb(235, 22, 22, 24)),
            CornerRadius = new CornerRadius(22),
            Padding = new Thickness(18),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            BorderThickness = new Thickness(1),
            BorderBrush = new SolidColorBrush(Color.FromArgb(22, 255, 255, 255)),
        };
        var stack = new StackPanel { Spacing = 12 };
        stack.Children.Add(Typo.Label("Set duration", 13, Palette.InkDim));
        stack.Children.Add(_wheel);
        card.Child = stack;
        host.Children.Add(card);
        host.PointerPressed += (_, e) =>
        {
            if (ReferenceEquals(e.OriginalSource, host))
                CloseWheel();
        };
        host.Tapped += (_, e) => e.Handled = true;
        return host;
    }

    private void OpenWheel()
    {
        if (_wheelOpen || _running)
            return;
        _wheel.SetSeconds((int)_total.TotalSeconds);
        _wheelOpen = true;
        _wheelHost.Opacity = 0;
        _wheelHost.Visibility = Visibility.Visible;
        Feedback.Light();
        new Tween(DispatcherQueue, 0, 1, 200, Ease.Standard, v => _wheelHost.Opacity = v);
    }

    private void CloseWheel()
    {
        if (!_wheelOpen)
            return;
        _wheelOpen = false;
        if (!_running)
        {
            var seconds = _wheel.TotalSeconds;
            if (seconds <= 0)
                seconds = 60;
            _total = TimeSpan.FromSeconds(seconds);
            _remaining = _total;
            AppServices.Settings.CountdownSeconds = seconds;
            AppServices.Settings.Save();
            UpdateVisuals();
        }
        Feedback.Light();
        new Tween(DispatcherQueue, 1, 0, 180, Ease.Standard, v => _wheelHost.Opacity = v,
            () => _wheelHost.Visibility = Visibility.Collapsed);
    }

    private static string Format(TimeSpan value)
    {
        if (value < TimeSpan.Zero)
            value = TimeSpan.Zero;
        return value.TotalHours >= 1
            ? $"{(int)value.TotalHours}:{value.Minutes:00}:{value.Seconds:00}"
            : $"{value.Minutes:00}:{value.Seconds:00}";
    }

    private static Button MakeButton(UIElement content, Action onClick)
    {
        var button = new Button
        {
            Content = content,
            Width = 46,
            Height = 46,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(23),
            Background = new SolidColorBrush(Color.FromArgb(14, 255, 255, 255)),
            BorderThickness = new Thickness(0),
            ElementSoundMode = ElementSoundMode.Off,
        };
        button.Click += (_, _) => onClick();
        return button;
    }
}
