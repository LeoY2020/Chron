using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;

namespace Chron.Controls;

/// <summary>
/// Pomodoro drag-scale: a tick scale with an inverted-triangle pointer above it.
/// Drag horizontally to change the value; ticks fire per graduation.
/// </summary>
public sealed class ScalePicker : Grid
{
    private readonly Canvas _ticks = new();
    private readonly Polygon _pointer = new();
    private readonly List<(Rectangle Rect, int Index)> _marks = new();
    private double _value = 25;
    private double _pxPerMin = 18;
    private bool _dragging;
    private Tween? _snap;
    private bool _built;

    public int Min { get; set; } = 1;
    public int Max { get; set; } = 90;

    public event Action<int>? ValueChanged;

    public int Value => Math.Clamp((int)Math.Round(_value), Min, Max);

    public ScalePicker()
    {
        Height = 150;
        Background = new SolidColorBrush(Color.FromArgb(1, 0, 0, 0));

        _ticks.VerticalAlignment = VerticalAlignment.Bottom;
        _ticks.Height = 96;
        Children.Add(_ticks);

        _pointer.VerticalAlignment = VerticalAlignment.Top;
        _pointer.HorizontalAlignment = HorizontalAlignment.Center;
        _pointer.StrokeThickness = 0;
        _pointer.Fill = new SolidColorBrush(Palette.Orange);
        _pointer.Points.Add(new Point(0, 0));
        _pointer.Points.Add(new Point(14, 0));
        _pointer.Points.Add(new Point(7, 12));
        Children.Add(_pointer);

        ManipulationMode = ManipulationModes.TranslateX | ManipulationModes.TranslateRailsX;
        ManipulationStarted += (_, _) => { _snap?.Stop(); _dragging = true; };
        ManipulationDelta += OnDelta;
        ManipulationCompleted += OnCompleted;
        PointerWheelChanged += OnWheel;
        SizeChanged += (_, _) => Build();
    }

    /// <summary>滚轮微调：向上加一分钟、向下减一分钟，避免与翻页手势争抢。</summary>
    private void OnWheel(object sender, PointerRoutedEventArgs e)
    {
        var delta = e.GetCurrentPoint(this).Properties.MouseWheelDelta;
        if (delta == 0)
            return;
        e.Handled = true;
        SetValue(Value + (delta > 0 ? 1 : -1), true);
        ValueChanged?.Invoke(Value);
        Feedback.Light();
    }

    public void SetValue(int value, bool animate)
    {
        var target = (double)Math.Clamp(value, Min, Max);
        if (!animate || !_built)
        {
            _value = target;
            Update();
            return;
        }
        _snap?.Stop();
        var from = _value;
        _snap = new Tween(DispatcherQueue, from, target, 260, Ease.OutCubic, v => { _value = v; Update(); });
    }

    private void Build()
    {
        if (ActualWidth <= 0)
            return;
        _pxPerMin = Math.Max(10, Math.Min(22, ActualWidth / 34.0));

        _ticks.Children.Clear();
        _marks.Clear();
        for (var i = Min; i <= Max; i++)
        {
            var major = i % 5 == 0;
            var rect = new Rectangle
            {
                Width = major ? 2 : 1.4,
                Height = major ? 34 : 18,
                Fill = new SolidColorBrush(major ? Palette.InkDim : Palette.InkFaint),
                RadiusX = 1,
                RadiusY = 1,
            };
            _marks.Add((rect, i));
            _ticks.Children.Add(rect);
        }

        _built = true;
        Update();
    }

    private void Update()
    {
        if (!_built || ActualWidth <= 0)
            return;
        var center = ActualWidth / 2;
        foreach (var (rect, index) in _marks)
        {
            var x = center + (index - _value) * _pxPerMin;
            if (x < -8 || x > ActualWidth + 8)
            {
                rect.Visibility = Visibility.Collapsed;
                continue;
            }
            rect.Visibility = Visibility.Visible;
            Canvas.SetLeft(rect, x);
            Canvas.SetTop(rect, _ticks.Height - rect.Height);
        }
    }

    private void OnDelta(object sender, ManipulationDeltaRoutedEventArgs e)
    {
        var previous = (int)Math.Round(_value);
        _value -= e.Delta.Translation.X / _pxPerMin;
        if (_value < Min)
            _value = Min + (_value - Min) * 0.35;
        if (_value > Max)
            _value = Max + (_value - Max) * 0.35;
        Update();

        var current = (int)Math.Round(_value);
        if (_dragging && current != previous && current >= Min && current <= Max)
        {
            Feedback.Light();
            ValueChanged?.Invoke(Value);
        }
    }

    private void OnCompleted(object sender, ManipulationCompletedRoutedEventArgs e)
    {
        _dragging = false;
        var target = Math.Clamp((int)Math.Round(_value), Min, Max);
        _snap?.Stop();
        _snap = new Tween(DispatcherQueue, _value, target, 240, Ease.OutBack,
            v => { _value = v; Update(); },
            () => ValueChanged?.Invoke(Value));
    }
}
