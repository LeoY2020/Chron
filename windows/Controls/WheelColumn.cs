using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Chron.Controls;

/// <summary>
/// A scroll-wheel column (hours / minutes / seconds). Drag or mouse-wheel to
/// change; snaps to the nearest value with a light tick per graduation and
/// rubber-banding at the ends.
/// </summary>
public sealed class WheelColumn : Grid
{
    private const int Pool = 7;
    private readonly List<TextBlock> _pool = new();
    private readonly List<TranslateTransform> _transforms = new();
    private double _value;
    private double _itemHeight = 52;
    private bool _dragging;
    private Tween? _snap;
    private int _lastTick;
    private bool _initialised;

    public int Min { get; set; }
    public int Max { get; set; } = 59;

    public event Action<int>? ValueCommitted;

    public int Value => Math.Clamp((int)Math.Round(_value), Min, Max);

    public WheelColumn()
    {
        Background = new SolidColorBrush(Color.FromArgb(1, 0, 0, 0));
        ManipulationMode = ManipulationModes.TranslateY | ManipulationModes.TranslateRailsY;
        ManipulationStarted += (_, _) => { _snap?.Stop(); _dragging = true; };
        ManipulationDelta += OnDelta;
        ManipulationCompleted += OnCompleted;
        PointerWheelChanged += OnWheel;
        SizeChanged += (_, _) =>
        {
            _itemHeight = Math.Max(34, ActualHeight / 5.0);
            Render();
        };

        for (var i = 0; i < Pool; i++)
        {
            var transform = new TranslateTransform();
            var tb = Typo.Digits("0", 30, Palette.InkDim);
            tb.HorizontalAlignment = HorizontalAlignment.Center;
            tb.VerticalAlignment = VerticalAlignment.Top;
            tb.RenderTransform = transform;
            _transforms.Add(transform);
            _pool.Add(tb);
            Children.Add(tb);
        }
    }

    public void SetRange(int min, int max)
    {
        Min = min;
        Max = max;
        _value = Math.Clamp(_value, min, max);
        Render();
    }

    public void SetValue(int value, bool animate)
    {
        var target = (double)Math.Clamp(value, Min, Max);
        _lastTick = (int)Math.Round(target);
        if (!animate || !_initialised)
        {
            _value = target;
            _initialised = true;
            Render();
            return;
        }
        _snap?.Stop();
        var from = _value;
        _snap = new Tween(DispatcherQueue, from, target, 240, Ease.OutCubic,
            v => { _value = v; Render(); });
    }

    private void Render()
    {
        if (ActualHeight <= 0 || ActualWidth <= 0)
            return;
        var center = (int)Math.Round(_value);
        const int half = Pool / 2;
        for (var i = 0; i < Pool; i++)
        {
            var index = center + (i - half);
            var tb = _pool[i];
            if (index < Min || index > Max)
            {
                tb.Visibility = Visibility.Collapsed;
                continue;
            }
            tb.Visibility = Visibility.Visible;
            tb.Text = index.ToString();
            tb.Width = ActualWidth;
            tb.Height = _itemHeight;

            var delta = index - _value;
            var distance = Math.Clamp(Math.Abs(delta) / half, 0, 1);
            tb.FontSize = 30 - 9 * distance;
            tb.Opacity = 1 - 0.78 * distance;
            tb.Foreground = new SolidColorBrush(Palette.Mix(Palette.Ink, Palette.InkFaint, distance));
            _transforms[i].Y = ActualHeight / 2 - _itemHeight / 2 + delta * _itemHeight;
        }
    }

    private void OnDelta(object sender, ManipulationDeltaRoutedEventArgs e)
    {
        var previous = (int)Math.Round(_value);
        _value -= e.Delta.Translation.Y / _itemHeight;
        if (_value < Min)
            _value = Min + (_value - Min) * 0.35;
        if (_value > Max)
            _value = Max + (_value - Max) * 0.35;
        Render();

        var current = (int)Math.Round(_value);
        if (_dragging && current != previous && current >= Min && current <= Max)
            Feedback.Light();
    }

    private void OnCompleted(object sender, ManipulationCompletedRoutedEventArgs e)
    {
        _dragging = false;
        var target = Math.Clamp((int)Math.Round(_value), Min, Max);
        _snap?.Stop();
        _snap = new Tween(DispatcherQueue, _value, target, 260, Ease.OutBack,
            v => { _value = v; Render(); },
            () => ValueCommitted?.Invoke(Value));
    }

    private void OnWheel(object sender, PointerRoutedEventArgs e)
    {
        var delta = e.GetCurrentPoint(this).Properties.MouseWheelDelta;
        if (delta == 0)
            return;
        var direction = delta > 0 ? 1 : -1;
        var target = Math.Clamp((int)Math.Round(_value) + direction, Min, Max);
        _value = (int)Math.Round(_value);
        if (target == (int)_value)
        {
            Render();
            e.Handled = true;
            return;
        }
        Feedback.Light();
        _snap?.Stop();
        _snap = new Tween(DispatcherQueue, _value, target, 170, Ease.OutCubic,
            v => { _value = v; Render(); },
            () => ValueCommitted?.Invoke(Value));
        e.Handled = true;
    }
}
