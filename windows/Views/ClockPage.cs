using Chron.Services;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;
using Microsoft.UI.Text;

namespace Chron.Views;

/// <summary>Clock screen. Five styles: Analog, Plain, Immersive, Segment, Sun.</summary>
public sealed class ClockPage : ClockPageBase
{
    private const double D = 320;
    private const double Cx = D / 2;
    private const double Cy = D / 2;
    private const double R = 130;
    private static readonly string[] Names = { "Analog", "Plain", "Immersive", "Segment", "Sun" };

    private readonly DispatcherQueueTimer _timer;

    private TextBlock? _digits;
    private RotateTransform? _hourRotation;
    private RotateTransform? _minuteRotation;
    private RotateTransform? _secondRotation;
    private SevenSegment? _segment;
    private LinearGradientBrush? _sunBrush;
    private Color _sunA;
    private Color _sunB;
    private Color _sunInk;
    private int _sunPeriod = -1;

    public ClockPage()
    {
        Ink = Palette.FromArgb(AppServices.Settings.ClockInk);

        _timer = DispatcherQueue.CreateTimer();
        _timer.Interval = TimeSpan.FromMilliseconds(50);
        _timer.IsRepeating = true;
        _timer.Tick += (_, _) => Update();

        InitializeStyle(AppServices.Settings.ClockStyle);
        Update();
        _timer.Start();
    }

    protected override int StyleCount => 5;
    protected override string StyleName(int index) => Names[index];

    protected override void OnStylePersisted(int index)
    {
        AppServices.Settings.ClockStyle = index;
        AppServices.Settings.Save();
    }

    protected override void OnOptionsPersisted()
    {
        AppServices.Settings.ClockInk = Palette.ToArgb(Ink);
        AppServices.Settings.Save();
    }

    protected override void OnStageResized()
    {
        if (StyleIndex == 1 && _digits is not null)
            _digits.FontSize = PlainFontSize();
    }

    protected override UIElement CreateStyleVisual(int index)
    {
        _digits = null;
        _hourRotation = null;
        _minuteRotation = null;
        _secondRotation = null;
        _segment = null;
        _sunBrush = null;
        _sunPeriod = -1;

        var visual = index switch
        {
            0 => BuildAnalog(),
            1 => BuildPlain(),
            2 => BuildImmersive(),
            3 => BuildSegment(),
            _ => BuildSun(),
        };
        Update();
        return visual;
    }

    private UIElement BuildAnalog()
    {
        var canvas = new Canvas { Width = D, Height = D };
        for (var i = 0; i < 60; i++)
        {
            var angle = i * 6 * Math.PI / 180.0;
            var major = i % 5 == 0;
            var inner = major ? R - 15 : R - 7;
            var line = new Line
            {
                X1 = Cx + inner * Math.Sin(angle),
                Y1 = Cy - inner * Math.Cos(angle),
                X2 = Cx + R * Math.Sin(angle),
                Y2 = Cy - R * Math.Cos(angle),
                Stroke = new SolidColorBrush(major
                    ? Color.FromArgb(150, 255, 255, 255)
                    : Color.FromArgb(60, 255, 255, 255)),
                StrokeThickness = major ? 2 : 1,
            };
            canvas.Children.Add(line);
        }

        _hourRotation = AddHand(canvas, 68, 6, Ink);
        _minuteRotation = AddHand(canvas, 98, 4, Ink);
        _secondRotation = AddHand(canvas, 114, 1.6, Palette.Orange);

        var hub = new Ellipse { Width = 9, Height = 9, Fill = new SolidColorBrush(Ink) };
        Canvas.SetLeft(hub, Cx - 4.5);
        Canvas.SetTop(hub, Cy - 4.5);
        canvas.Children.Add(hub);

        return new Viewbox
        {
            Child = canvas,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(56),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
    }

    private static RotateTransform AddHand(Canvas canvas, double length, double thickness, Color color)
    {
        var rotation = new RotateTransform { CenterX = thickness / 2, CenterY = length };
        var hand = new Rectangle
        {
            Width = thickness,
            Height = length,
            RadiusX = thickness / 2,
            RadiusY = thickness / 2,
            Fill = new SolidColorBrush(color),
            RenderTransform = rotation,
        };
        Canvas.SetLeft(hand, Cx - thickness / 2);
        Canvas.SetTop(hand, Cy - length);
        canvas.Children.Add(hand);
        return rotation;
    }

    private UIElement BuildPlain()
    {
        var root = new Grid();
        _digits = Typo.Digits(TimeText(), PlainFontSize(), Ink);
        root.Children.Add(_digits);
        return root;
    }

    private UIElement BuildImmersive()
    {
        _digits = Typo.Digits(TimeText(), 220, Ink, FontWeights.SemiBold);
        return new Viewbox
        {
            Child = _digits,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(28, 64, 28, 64),
        };
    }

    private UIElement BuildSegment()
    {
        _segment = new SevenSegment();
        _segment.SetTime(TimeText());
        return _segment;
    }

    private UIElement BuildSun()
    {
        _sunPeriod = SunPeriod(DateTime.Now.Hour);
        var (top, bottom, ink) = SunPreset(_sunPeriod);
        _sunA = top;
        _sunB = bottom;
        _sunInk = ink;

        _sunBrush = new LinearGradientBrush { StartPoint = new Point(0, 0), EndPoint = new Point(1, 1) };
        _sunBrush.GradientStops.Add(new GradientStop { Color = top, Offset = 0 });
        _sunBrush.GradientStops.Add(new GradientStop { Color = bottom, Offset = 1 });

        var root = new Grid();
        root.Children.Add(new Rectangle { Fill = _sunBrush });
        _digits = Typo.Digits(TimeText(), 220, ink, FontWeights.SemiBold);
        root.Children.Add(new Viewbox
        {
            Child = _digits,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(28, 64, 28, 64),
        });
        return root;
    }

    private double PlainFontSize() =>
        Math.Max(40, Math.Min(Math.Max(1, Stage.ActualWidth) / 4.6, Math.Max(1, Stage.ActualHeight) * 0.28));

    private void Update()
    {
        var now = DateTime.Now;

        if (_hourRotation is not null)
            _hourRotation.Angle = now.Hour % 12 * 30 + now.Minute * 0.5 + now.Second * (0.5 / 60.0);
        if (_minuteRotation is not null)
            _minuteRotation.Angle = now.Minute * 6 + now.Second * 0.1;
        if (_secondRotation is not null)
            _secondRotation.Angle = now.Second * 6 + now.Millisecond * 0.006;

        var text = now.ToString("HH:mm:ss");
        if (_digits is not null && _digits.Text != text)
            _digits.Text = text;
        if (_segment is not null)
            _segment.SetTime(text);
        if (_sunBrush is not null)
            UpdateSun(now);
    }

    private void UpdateSun(DateTime now)
    {
        var period = SunPeriod(now.Hour);
        if (period == _sunPeriod)
            return;
        _sunPeriod = period;

        var (top, bottom, ink) = SunPreset(period);
        var fromTop = _sunA;
        var fromBottom = _sunB;
        var brush = _sunBrush!;

        new Tween(DispatcherQueue, 0, 1, 2200, Ease.Standard, v =>
        {
            _sunA = Palette.Mix(fromTop, top, v);
            _sunB = Palette.Mix(fromBottom, bottom, v);
            brush.GradientStops[0].Color = _sunA;
            brush.GradientStops[1].Color = _sunB;
        });

        _sunInk = ink;
        if (_digits is not null)
            _digits.Foreground = new SolidColorBrush(ink);
    }

    private static string TimeText() => DateTime.Now.ToString("HH:mm:ss");

    private static int SunPeriod(int hour)
    {
        if (hour >= 22 || hour < 5)
            return 0; // night
        if (hour < 8)
            return 1; // dawn
        if (hour < 17)
            return 2; // day
        return 3;     // dusk
    }

    private static (Color Top, Color Bottom, Color Ink) SunPreset(int period) => period switch
    {
        0 => (Color.FromArgb(255, 10, 14, 26), Color.FromArgb(255, 5, 6, 10), Color.FromArgb(255, 201, 211, 255)),
        1 => (Color.FromArgb(255, 42, 27, 46), Color.FromArgb(255, 18, 12, 22), Color.FromArgb(255, 255, 184, 154)),
        2 => (Color.FromArgb(255, 22, 34, 44), Color.FromArgb(255, 10, 16, 22), Color.FromArgb(255, 255, 243, 218)),
        _ => (Color.FromArgb(255, 42, 21, 8), Color.FromArgb(255, 16, 8, 4), Color.FromArgb(255, 255, 176, 103)),
    };
}
