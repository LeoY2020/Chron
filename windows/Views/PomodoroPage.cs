using Chron.Controls;
using Chron.Services;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;

namespace Chron.Views;

/// <summary>
/// Pomodoro screen. Warm orange focus timer with a pull-down summary and a
/// drag-scale duration picker. Break mode is visually distinct (cooler).
/// </summary>
public sealed class PomodoroPage : Grid
{
    private enum Mode { Focus, Break }

    private const double SummaryHeight = 220;

    private readonly DispatcherQueueTimer _timer;
    private readonly Rectangle _background = new();
    private readonly LinearGradientBrush _bgBrush = new() { StartPoint = new Point(0, 0), EndPoint = new Point(1, 1) };
    private readonly TextBlock _label;
    private readonly TextBlock _digits;
    private readonly ScalePicker _picker = new();
    private readonly StackPanel _controls;
    private readonly FontIcon _playIcon;
    private readonly Button _playButton;
    private readonly Grid _summary = new();
    private readonly TranslateTransform _summaryShift = new();
    private readonly Grid _handle = new();

    private Mode _mode = Mode.Focus;
    private TimeSpan _total;
    private TimeSpan _remaining;
    private bool _running;
    private bool _picking;
    private bool _summaryOpen;
    private long _lastTicks;

    public PomodoroPage()
    {
        Clip = new RectangleGeometry();

        _bgBrush.GradientStops.Add(new GradientStop { Color = Palette.PomodoroBg, Offset = 0 });
        _bgBrush.GradientStops.Add(new GradientStop { Color = Color.FromArgb(255, 12, 9, 6), Offset = 1 });
        _background.Fill = _bgBrush;
        Children.Add(_background);

        _label = Typo.Label("FOCUS", 13, Palette.InkDim);
        _label.Margin = new Thickness(0, 0, 0, 6);

        _digits = Typo.Digits(Format(_remaining), 200, Palette.Amber, Microsoft.UI.Text.FontWeights.SemiBold);
        _digits.Tapped += (_, e) =>
        {
            if (_picking)
                EndPick();
            else
                BeginPick();
            e.Handled = true;
        };

        var digitView = new Viewbox
        {
            Child = _digits,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(40, 40, 40, 40),
        };

        _picker.Visibility = Visibility.Collapsed;
        _picker.ValueChanged += _ => UpdateDigits();
        _picker.Tapped += (_, e) => e.Handled = true;

        var content = new Grid { HorizontalAlignment = HorizontalAlignment.Stretch, VerticalAlignment = VerticalAlignment.Stretch };
        content.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        content.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        content.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        SetRow(_label, 0);
        content.Children.Add(_label);
        SetRow(digitView, 1);
        content.Children.Add(digitView);
        SetRow(_picker, 2);
        content.Children.Add(_picker);
        Children.Add(content);

        _playIcon = new FontIcon
        {
            Glyph = "\uE768",
            FontSize = 16,
            FontFamily = new FontFamily("Segoe Fluent Icons"),
            Foreground = new SolidColorBrush(Palette.InkDim),
        };
        _playButton = MakeButton(_playIcon, ToggleRunning, "开始 / 暂停 (空格)");
        var resetButton = MakeButton(new FontIcon
        {
            Glyph = "\uE72C",
            FontSize = 16,
            FontFamily = new FontFamily("Segoe Fluent Icons"),
            Foreground = new SolidColorBrush(Palette.InkDim),
        }, Reset, "重置 (R)");
        _controls = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 18,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0, 0, 0, 40),
        };
        _controls.Children.Add(_playButton);
        _controls.Children.Add(resetButton);
        Children.Add(_controls);

        BuildHandle();
        BuildSummary();
        Children.Add(_summary);
        Children.Add(_handle);

        _total = TimeSpan.FromMinutes(Math.Max(1, AppServices.Settings.FocusMinutes));
        _remaining = _total;
        ApplyMode();
        UpdateDigits();

        _timer = DispatcherQueue.CreateTimer();
        _timer.Interval = TimeSpan.FromMilliseconds(200);
        _timer.IsRepeating = true;
        _timer.Tick += OnTimerTick;

        SizeChanged += (_, _) =>
        {
            if (Clip is RectangleGeometry clip)
                clip.Rect = new Rect(0, 0, ActualWidth, ActualHeight);
        };
    }

    public void PrimaryAction() => ToggleRunning();

    private void BuildHandle()
    {
        _handle.Height = 56;
        _handle.VerticalAlignment = VerticalAlignment.Top;
        _handle.Background = new SolidColorBrush(Color.FromArgb(1, 0, 0, 0));
        _handle.ManipulationMode = ManipulationModes.TranslateY | ManipulationModes.TranslateRailsY;

        var capsule = new Border
        {
            Width = 40,
            Height = 4,
            CornerRadius = new CornerRadius(2),
            Background = new SolidColorBrush(Color.FromArgb(60, 255, 255, 255)),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
        _handle.Children.Add(capsule);

        _handle.ManipulationStarted += (_, _) => _handle.Opacity = 1;
        _handle.ManipulationDelta += (_, e) =>
        {
            var current = _summaryShift.Y + e.Delta.Translation.Y;
            if (current > 0)
                current *= 0.3;
            else if (current < -SummaryHeight)
                current = -SummaryHeight + (current + SummaryHeight) * 0.3;
            _summaryShift.Y = current;
        };
        _handle.ManipulationCompleted += (_, _) => SettleSummary();
        _handle.Tapped += (_, e) =>
        {
            ToggleSummary();
            e.Handled = true;
        };
    }

    private void BuildSummary()
    {
        _summary.Height = SummaryHeight;
        _summary.VerticalAlignment = VerticalAlignment.Top;
        _summary.Margin = new Thickness(0, 56, 0, 0);
        _summary.RenderTransform = _summaryShift;
        _summaryShift.Y = -SummaryHeight;
        _summary.Background = new SolidColorBrush(Color.FromArgb(230, 18, 12, 8));
        _summary.Padding = new Thickness(28, 20, 28, 20);
        _summary.Tapped += (_, e) => e.Handled = true;
    }

    private void RefreshSummary()
    {
        _summary.Children.Clear();
        var store = AppServices.Pomodoro;
        var stack = new StackPanel { Spacing = 6 };
        stack.Children.Add(Typo.Label($"Today   {store.TodayCount} sessions · {store.TodayMinutes} min", 14, Palette.Amber));
        stack.Children.Add(Typo.Label($"This week   {store.WeekCount} sessions · {store.WeekMinutes} min", 14, Palette.InkDim));

        var minutes = store.Last7Minutes();
        var max = Math.Max(1, minutes.Max());
        var bars = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 6,
            Height = 64,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0, 10, 0, 0),
        };
        foreach (var value in minutes)
        {
            var column = new Grid { Width = 18, VerticalAlignment = VerticalAlignment.Bottom };
            var height = Math.Max(3, 56.0 * value / max);
            column.Children.Add(new Rectangle
            {
                Height = height,
                Width = 10,
                RadiusX = 3,
                RadiusY = 3,
                Fill = new SolidColorBrush(Color.FromArgb(190, 255, 149, 0)),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Bottom,
            });
            bars.Children.Add(column);
        }
        stack.Children.Add(bars);
        _summary.Children.Add(stack);
    }

    private void ToggleSummary()
    {
        _summaryOpen = !_summaryOpen;
        Feedback.Medium();
        if (_summaryOpen)
            RefreshSummary();
        SettleSummary();
    }

    private void SettleSummary()
    {
        var target = _summaryOpen ? 0.0 : -SummaryHeight;
        var from = _summaryShift.Y;
        _summaryShift.Y = from;
        new Tween(DispatcherQueue, from, target, 320, Ease.OutCubic, v => _summaryShift.Y = v);
    }

    private void OnTimerTick(DispatcherQueueTimer sender, object args)
    {
        var now = Environment.TickCount64;
        var elapsed = TimeSpan.FromMilliseconds(now - _lastTicks);
        _lastTicks = now;
        if (!_running || _picking)
            return;

        _remaining -= elapsed;
        if (_remaining <= TimeSpan.Zero)
        {
            _remaining = TimeSpan.Zero;
            UpdateDigits();
            Complete();
            return;
        }
        UpdateDigits();
    }

    private void Complete()
    {
        if (_mode == Mode.Focus)
        {
            var minutes = Math.Max(1, (int)Math.Round(_total.TotalMinutes));
            AppServices.Pomodoro.Add(new FocusSession
            {
                Start = DateTime.Now.AddMinutes(-minutes),
                Minutes = minutes,
                Completed = true,
                Break = false,
            });
            Feedback.Heavy();
            Motion.Pulse(_digits, 0.95f, 280);
            _mode = Mode.Break;
            _total = TimeSpan.FromMinutes(Math.Max(1, AppServices.Settings.BreakMinutes));
            _remaining = _total;
            _running = true;
            _lastTicks = Environment.TickCount64;
        }
        else
        {
            Feedback.Heavy();
            Motion.Pulse(_digits, 0.95f, 280);
            _mode = Mode.Focus;
            _total = TimeSpan.FromMinutes(Math.Max(1, AppServices.Settings.FocusMinutes));
            _remaining = _total;
            _running = false;
            _timer.Stop();
        }
        ApplyMode();
        UpdatePlayIcon();
        UpdateDigits();
    }

    private void ToggleRunning()
    {
        if (_picking)
            EndPick();
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

    /// <summary>键盘 R：回到当前阶段起点，不写入专注记录。</summary>
    public void ResetPhase() => Reset();

    private void Reset()
    {
        _running = false;
        _timer.Stop();
        _mode = Mode.Focus;
        _total = TimeSpan.FromMinutes(Math.Max(1, AppServices.Settings.FocusMinutes));
        _remaining = _total;
        ApplyMode();
        UpdatePlayIcon();
        UpdateDigits();
        Feedback.Light();
    }

    private void BeginPick()
    {
        if (_running)
            return;
        _picking = true;
        _picker.SetValue(Math.Max(1, (int)Math.Round(_total.TotalMinutes)), false);
        _picker.Visibility = Visibility.Visible;
        _controls.Visibility = Visibility.Collapsed;
        UpdateDigits();
        Feedback.Light();
    }

    private void EndPick()
    {
        if (!_picking)
            return;
        _picking = false;
        var minutes = Math.Max(1, _picker.Value);
        if (_mode == Mode.Focus)
            AppServices.Settings.FocusMinutes = minutes;
        else
            AppServices.Settings.BreakMinutes = minutes;
        AppServices.Settings.Save();
        _total = TimeSpan.FromMinutes(minutes);
        _remaining = _total;
        _picker.Visibility = Visibility.Collapsed;
        _controls.Visibility = Visibility.Visible;
        UpdateDigits();
        Feedback.Light();
    }

    private void ApplyMode()
    {
        var focus = _mode == Mode.Focus;
        _label.Text = focus ? "FOCUS" : "BREAK";
        _bgBrush.GradientStops[0].Color = focus ? Palette.PomodoroBg : Palette.PomodoroBreakBg;
        _bgBrush.GradientStops[1].Color = focus ? Color.FromArgb(255, 12, 9, 6) : Color.FromArgb(255, 7, 12, 11);
        _digits.Foreground = new SolidColorBrush(focus ? Palette.Amber : Palette.Teal);
    }

    private void UpdatePlayIcon() => _playIcon.Glyph = _running ? "\uE769" : "\uE768";

    private void UpdateDigits()
    {
        var value = _picking ? TimeSpan.FromMinutes(_picker.Value) : _remaining;
        _digits.Text = Format(value);
    }

    private static string Format(TimeSpan value)
    {
        if (value < TimeSpan.Zero)
            value = TimeSpan.Zero;
        return value.TotalHours >= 1
            ? $"{(int)value.TotalHours}:{value.Minutes:00}:{value.Seconds:00}"
            : $"{value.Minutes:00}:{value.Seconds:00}";
    }

    private static Button MakeButton(UIElement content, Action onClick, string? tooltip = null)
    {
        var rest = Color.FromArgb(16, 255, 255, 255);
        var hover = Color.FromArgb(32, 255, 255, 255);
        var press = Color.FromArgb(46, 255, 255, 255);
        var button = new Button
        {
            Content = content,
            Width = 46,
            Height = 46,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(23),
            Background = new SolidColorBrush(rest),
            BorderThickness = new Thickness(0),
            ElementSoundMode = ElementSoundMode.Off,
        };

        // 鼠标悬停与按下反馈。
        button.PointerEntered += (_, _) => button.Background = new SolidColorBrush(hover);
        button.PointerExited += (_, _) => button.Background = new SolidColorBrush(rest);
        button.PointerPressed += (_, _) => button.Background = new SolidColorBrush(press);
        button.PointerReleased += (_, _) => button.Background = new SolidColorBrush(hover);

        if (tooltip is not null)
            ToolTipService.SetToolTip(button, tooltip);

        button.Click += (_, _) =>
        {
            button.Background = new SolidColorBrush(hover);
            onClick();
        };
        return button;
    }
}

