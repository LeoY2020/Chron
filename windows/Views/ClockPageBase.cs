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
/// Shared shell for the Countdown and Clock screens: a shrinkable stage, a
/// bottom style bar and an in-place editor. Long-press (touch, ~480 ms) or
/// right-click toggles the shrunken state; paging is locked while shrunken.
/// </summary>
public abstract class ClockPageBase : Grid
{
    protected readonly Grid Stage = new();
    protected readonly Grid StyleLayer = new();
    protected readonly Grid OverlayLayer = new();
    protected readonly StyleBar Bar = new();
    protected readonly Rectangle Scrim = new();

    private readonly ScaleTransform _scale = new();
    private readonly RectangleGeometry _clip = new();
    private Tween? _scaleTween;
    private Tween? _scrimTween;
    private DispatcherQueueTimer? _hold;
    private Point _pressPoint;
    private bool _shrunken;
    private bool _suppressTap;
    private EditorPanel? _editor;

    public event Action<bool>? PagingLockChanged;

    public Color Ink { get; protected set; } = Palette.Ink;
    public double RingThickness { get; protected set; } = 10;
    public bool IsShrunken => _shrunken;

    protected int StyleIndex { get; private set; }

    protected abstract int StyleCount { get; }
    protected abstract string StyleName(int index);
    protected abstract UIElement CreateStyleVisual(int index);
    protected virtual bool SupportsThickness => false;

    protected ClockPageBase()
    {
        Background = new SolidColorBrush(Palette.Bg);
        Clip = _clip;

        Stage.RenderTransform = _scale;
        Stage.HorizontalAlignment = HorizontalAlignment.Stretch;
        Stage.VerticalAlignment = VerticalAlignment.Stretch;
        StyleLayer.HorizontalAlignment = HorizontalAlignment.Stretch;
        StyleLayer.VerticalAlignment = VerticalAlignment.Stretch;
        OverlayLayer.HorizontalAlignment = HorizontalAlignment.Stretch;
        OverlayLayer.VerticalAlignment = VerticalAlignment.Stretch;
        Stage.Children.Add(StyleLayer);
        Stage.Children.Add(OverlayLayer);
        Children.Add(Stage);

        var scrim = new LinearGradientBrush { StartPoint = new Point(0, 0), EndPoint = new Point(0, 1) };
        scrim.GradientStops.Add(new GradientStop { Color = Color.FromArgb(0, 0, 0, 0), Offset = 0 });
        scrim.GradientStops.Add(new GradientStop { Color = Color.FromArgb(215, 0, 0, 0), Offset = 1 });
        Scrim.Fill = scrim;
        Scrim.VerticalAlignment = VerticalAlignment.Bottom;
        Scrim.Height = 190;
        Scrim.Opacity = 0;
        Scrim.IsHitTestVisible = false;
        Children.Add(Scrim);

        Children.Add(Bar);
        Bar.Selected += OnBarSelected;

        PointerPressed += HandlePointerPressed;
        PointerMoved += HandlePointerMoved;
        PointerReleased += HandlePointerReleased;
        PointerCanceled += HandlePointerCanceled;
        Tapped += HandleTapped;

        SizeChanged += (_, _) =>
        {
            _clip.Rect = new Rect(0, 0, ActualWidth, ActualHeight);
            _scale.CenterX = ActualWidth / 2;
            _scale.CenterY = ActualHeight / 2;
            OnStageResized();
        };
    }

    protected void InitializeStyle(int index)
    {
        StyleIndex = Math.Clamp(index, 0, StyleCount - 1);
        Redraw();
    }

    protected void SetStyle(int index, bool persist = true)
    {
        index = Math.Clamp(index, 0, StyleCount - 1);
        var changed = index != StyleIndex;
        StyleIndex = index;
        Redraw();
        Bar.SetSelected(index);
        if (changed)
            OnStyleChanged(index);
        if (persist)
            OnStylePersisted(index);
    }

    protected virtual void OnStyleChanged(int index) { }
    protected virtual void OnStylePersisted(int index) { }
    protected virtual void OnOptionsPersisted() { }
    protected virtual void OnStageResized() { }

    protected void Redraw()
    {
        StyleLayer.Children.Clear();
        var visual = CreateStyleVisual(StyleIndex);
        if (visual is FrameworkElement element)
        {
            element.HorizontalAlignment = HorizontalAlignment.Stretch;
            element.VerticalAlignment = VerticalAlignment.Stretch;
        }
        StyleLayer.Children.Add(visual);
    }

    protected void ToggleShrink()
    {
        _shrunken = !_shrunken;
        _suppressTap = true;
        PagingLockChanged?.Invoke(_shrunken);
        Feedback.Medium();
        CloseEditor();
        if (_shrunken)
        {
            Bar.SetItems(StyleNames(), StyleIndex);
            Bar.Show();
            AnimateScale(0.92, 340, Ease.OutBack);
            AnimateScrim(1, 300);
        }
        else
        {
            Bar.Hide();
            AnimateScale(1.0, 300, Ease.Standard);
            AnimateScrim(0, 240);
        }
    }

    private string[] StyleNames()
    {
        var names = new string[StyleCount];
        for (var i = 0; i < StyleCount; i++)
            names[i] = StyleName(i);
        return names;
    }

    private void AnimateScale(double to, double ms, Func<double, double> ease)
    {
        _scaleTween?.Stop();
        var from = _scale.ScaleX;
        _scaleTween = new Tween(DispatcherQueue, from, to, ms, ease, v =>
        {
            _scale.ScaleX = v;
            _scale.ScaleY = v;
        });
    }

    private void AnimateScrim(double to, double ms)
    {
        _scrimTween?.Stop();
        var from = Scrim.Opacity;
        _scrimTween = new Tween(DispatcherQueue, from, to, ms, Ease.Standard, v => Scrim.Opacity = v);
    }

    private void OnBarSelected(int index)
    {
        if (index == StyleIndex)
        {
            OpenEditor();
            return;
        }
        SetStyle(index);
    }

    private void OpenEditor()
    {
        if (_editor is null)
        {
            _editor = new EditorPanel(SupportsThickness, Ink, RingThickness);
            _editor.HorizontalAlignment = HorizontalAlignment.Center;
            _editor.VerticalAlignment = VerticalAlignment.Bottom;
            _editor.Margin = new Thickness(0, 0, 0, 112);
            _editor.Changed += (ink, thickness) =>
            {
                Ink = ink;
                RingThickness = thickness;
                Redraw();
                OnOptionsPersisted();
            };
            Children.Add(_editor);
        }
        Feedback.Light();
        _editor.Show();
    }

    private void CloseEditor() => _editor?.Hide();

    /// <summary>Esc 分级退出：先收起就地编辑器，再退出收缩态。返回是否消费了这次按键。</summary>
    public bool CloseOverlay()
    {
        if (_editor is { IsOpen: true })
        {
            CloseEditor();
            return true;
        }
        if (_shrunken)
        {
            ToggleShrink();
            return true;
        }
        return false;
    }

    protected void AttachDigitTap(TextBlock digits, Action onTap)
    {
        digits.Tapped += (_, e) =>
        {
            if (IsShrunken)
                return;
            onTap();
            e.Handled = true;
        };
    }

    private void HandlePointerPressed(object sender, PointerRoutedEventArgs e)
    {

        var point = e.GetCurrentPoint(this);
        if (point.Properties.IsRightButtonPressed)
        {
            ToggleShrink();
            e.Handled = true;
            return;
        }
        _pressPoint = point.Position;
        StartHold();
    }

    private void HandlePointerMoved(object sender, PointerRoutedEventArgs e)
    {

        if (_hold is null)
            return;
        var position = e.GetCurrentPoint(this).Position;
        if (Math.Abs(position.X - _pressPoint.X) > 10 || Math.Abs(position.Y - _pressPoint.Y) > 10)
            CancelHold();
    }

    private void HandlePointerReleased(object sender, PointerRoutedEventArgs e)
    {

        CancelHold();
    }

    private void HandlePointerCanceled(object sender, PointerRoutedEventArgs e)
    {

        CancelHold();
    }

    private void HandleTapped(object sender, TappedRoutedEventArgs e)
    {

        if (_suppressTap)
        {
            _suppressTap = false;
            e.Handled = true;
            return;
        }
        if (_shrunken)
        {
            ToggleShrink();
            e.Handled = true;
        }
    }

    private void StartHold()
    {
        CancelHold();
        _hold = DispatcherQueue.CreateTimer();
        _hold.Interval = TimeSpan.FromMilliseconds(480);
        _hold.IsRepeating = false;
        _hold.Tick += (_, _) =>
        {
            _hold = null;
            ToggleShrink();
        };
        _hold.Start();
    }

    private void CancelHold()
    {
        if (_hold is null)
            return;
        _hold.Stop();
        _hold = null;
    }
}
