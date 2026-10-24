using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.Foundation;

namespace Chron.Controls;

/// <summary>
/// Full-screen horizontal pager. Pages are laid side by side on a translated
/// track; the container handles touch / trackpad translation with inertia and
/// boundary rubber-banding.
/// </summary>
public sealed class PagingView : Grid
{
    private readonly Canvas _track = new();
    private readonly TranslateTransform _translation = new();
    private readonly RectangleGeometry _clip = new();
    private readonly List<FrameworkElement> _pages = new();
    private Tween? _tween;
    private double _width = 1;
    private double _offset;
    private double _drag;
    private bool _manipulating;

    public int Count => _pages.Count;
    public int CurrentIndex { get; private set; }

    private bool _pagingEnabled = true;
    public bool IsPagingEnabled
    {
        get => _pagingEnabled;
        set
        {
            _pagingEnabled = value;
            if (!value && _manipulating)
            {
                _manipulating = false;
                GoTo(CurrentIndex);
            }
        }
    }

    public event Action<int>? IndexChanged;

    public PagingView()
    {
        Clip = _clip;
        _track.RenderTransform = _translation;
        Children.Add(_track);

        ManipulationMode = ManipulationModes.TranslateX | ManipulationModes.TranslateRailsX;
        ManipulationStarted += OnManipulationStarted;
        ManipulationDelta += OnManipulationDelta;
        ManipulationCompleted += OnManipulationCompleted;
        PointerWheelChanged += OnPointerWheel;
        SizeChanged += (_, _) => LayoutPages();
    }

    private long _lastWheelTick;

    /// <summary>滚轮切页：空白区域的纵向/横向滚轮都能翻页；Shift+滚轮同样有效。</summary>
    private void OnPointerWheel(object sender, PointerRoutedEventArgs e)
    {
        if (!IsPagingEnabled)
            return;

        var delta = e.GetCurrentPoint(this).Properties.MouseWheelDelta;
        if (delta == 0)
            return;

        e.Handled = true;

        // 一次手势只翻一页，避免高速滚轮连翻。
        var now = Environment.TickCount64;
        if (now - _lastWheelTick < 240)
            return;
        _lastWheelTick = now;

        if (delta < 0)
            Next();
        else
            Previous();
    }

    public void AddPage(FrameworkElement page)
    {
        page.HorizontalAlignment = HorizontalAlignment.Left;
        page.VerticalAlignment = VerticalAlignment.Top;
        _pages.Add(page);
        _track.Children.Add(page);
        LayoutPages();
    }

    public void GoTo(int index, bool animate = true)
    {
        if (Count == 0)
            return;
        index = Math.Clamp(index, 0, Count - 1);
        var target = index * _width;
        var announce = index != CurrentIndex;
        CurrentIndex = index;
        if (announce)
            IndexChanged?.Invoke(index);

        if (!animate || _width <= 0)
        {
            _tween?.Stop();
            _offset = target;
            _drag = 0;
            Apply();
            return;
        }
        Animate(_offset + _drag, target, 380);
    }

    public void Next() => GoTo(CurrentIndex + 1);

    public void Previous() => GoTo(CurrentIndex - 1);

    private void LayoutPages()
    {
        _width = ActualWidth;
        var height = ActualHeight;
        if (_width <= 0 || height <= 0 || Count == 0)
            return;

        _clip.Rect = new Rect(0, 0, _width, height);
        _track.Width = _width * Count;
        _track.Height = height;
        for (var i = 0; i < Count; i++)
        {
            var page = _pages[i];
            page.Width = _width;
            page.Height = height;
            Canvas.SetLeft(page, i * _width);
            Canvas.SetTop(page, 0);
        }
        _offset = CurrentIndex * _width;
        _drag = 0;
        Apply();
    }

    private void Apply() => _translation.X = -(_offset + _drag);

    private void Animate(double from, double to, double ms, Func<double, double>? ease = null)
    {
        _tween?.Stop();
        _tween = new Tween(DispatcherQueue, from, to, ms, ease ?? Ease.Standard, value =>
        {
            _offset = value;
            _drag = 0;
            Apply();
        });
    }

    private void OnManipulationStarted(object sender, ManipulationStartedRoutedEventArgs e)
    {
        if (!IsPagingEnabled)
            return;
        _tween?.Stop();
        _manipulating = true;
        _drag = 0;
    }

    private void OnManipulationDelta(object sender, ManipulationDeltaRoutedEventArgs e)
    {
        if (!IsPagingEnabled || !_manipulating)
            return;
        var max = (Count - 1) * _width;
        // finger moves right -> content follows right -> offset decreases
        var current = _offset + _drag - e.Delta.Translation.X;
        if (current < 0)
            current = -Rubber(-current);
        else if (current > max)
            current = max + Rubber(current - max);
        _drag = current - _offset;
        Apply();
    }

    private void OnManipulationCompleted(object sender, ManipulationCompletedRoutedEventArgs e)
    {
        if (!IsPagingEnabled || !_manipulating)
            return;
        _manipulating = false;

        var velocity = e.Velocities.Linear.X; // px/ms, positive = to the right
        var position = _offset + _drag;
        var anchor = CurrentIndex * _width;
        var threshold = _width * 0.30;

        var target = CurrentIndex;
        if (velocity < -0.25 || position > anchor + threshold)
            target = CurrentIndex + 1;
        else if (velocity > 0.25 || position < anchor - threshold)
            target = CurrentIndex - 1;
        target = Math.Clamp(target, 0, Count - 1);

        var announce = target != CurrentIndex;
        CurrentIndex = target;
        if (announce)
            IndexChanged?.Invoke(target);

        var duration = 340 + Math.Min(260, Math.Abs(velocity) * 420);
        Animate(position, target * _width, duration);
    }

    private static double Rubber(double distance) => distance * 0.35;
}
