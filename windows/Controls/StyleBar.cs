using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.Foundation;
using Windows.UI;

namespace Chron.Controls;

/// <summary>Bottom style bar: slides in when a page shrinks, tap a style to switch.</summary>
public sealed class StyleBar : Grid
{
    private readonly StackPanel _row = new()
    {
        Orientation = Orientation.Horizontal,
        Spacing = 8,
        HorizontalAlignment = HorizontalAlignment.Center,
        VerticalAlignment = VerticalAlignment.Center,
    };

    private readonly TranslateTransform _translation = new();
    private readonly List<Button> _buttons = new();
    private Tween? _tween;
    private int _selected;

    public event Action<int>? Selected;

    public StyleBar()
    {
        Height = 96;
        VerticalAlignment = VerticalAlignment.Bottom;
        Opacity = 0;
        IsHitTestVisible = false;
        RenderTransform = _translation;
        _translation.Y = Height;

        var scrim = new LinearGradientBrush
        {
            StartPoint = new Point(0, 0),
            EndPoint = new Point(0, 1),
        };
        scrim.GradientStops.Add(new GradientStop { Color = Color.FromArgb(0, 0, 0, 0), Offset = 0 });
        scrim.GradientStops.Add(new GradientStop { Color = Color.FromArgb(235, 0, 0, 0), Offset = 1 });
        Background = scrim;

        // 玻璃质感面板：深色半透明 + 1px 细描边 + 24 圆角。
        var card = new Border
        {
            Background = new SolidColorBrush(Color.FromArgb(232, 22, 23, 26)),
            BorderBrush = new SolidColorBrush(Color.FromArgb(20, 255, 255, 255)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(24),
            Padding = new Thickness(10, 8, 10, 8),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 0, 8),
            Child = _row,
        };
        Children.Add(card);
    }

    public void SetItems(IReadOnlyList<string> names, int selected)
    {
        _selected = selected;
        _row.Children.Clear();
        _buttons.Clear();
        for (var i = 0; i < names.Count; i++)
        {
            var index = i;
            var button = new Button
            {
                Content = Typo.Label(names[i], 13, selected == i ? Palette.Ink : Palette.InkDim),
                Padding = new Thickness(16, 8, 16, 8),
                CornerRadius = new CornerRadius(18),
                BorderThickness = new Thickness(0),
                ElementSoundMode = ElementSoundMode.Off,
            };

            var hovering = false;
            Paint(button, index, hovering, false);
            button.PointerEntered += (_, _) =>
            {
                hovering = true;
                Paint(button, index, hovering, false);
            };
            button.PointerExited += (_, _) =>
            {
                hovering = false;
                Paint(button, index, hovering, false);
            };
            button.PointerPressed += (_, _) => Paint(button, index, hovering, true);
            button.PointerReleased += (_, _) => Paint(button, index, hovering, false);

            button.Click += (_, _) =>
            {
                Feedback.Light();
                Motion.Pulse(button);
                Selected?.Invoke(index);
            };
            _buttons.Add(button);
            _row.Children.Add(button);
        }
    }

    /// <summary>按选中 / 悬停 / 按下三种状态刷新按钮底色与文字亮度。</summary>
    private void Paint(Button button, int index, bool hovering, bool pressed)
    {
        var active = index == _selected;
        var alpha = active
            ? (hovering ? 56 : 38)
            : (pressed ? 32 : hovering ? 26 : 16);
        button.Background = new SolidColorBrush(Color.FromArgb((byte)alpha, 255, 255, 255));
        if (button.Content is TextBlock text)
            text.Foreground = new SolidColorBrush(active || hovering ? Palette.Ink : Palette.InkDim);
    }

    public void SetSelected(int selected)
    {
        _selected = selected;
        for (var i = 0; i < _buttons.Count; i++)
            Paint(_buttons[i], i, false, false);
    }

    public void Show()
    {
        IsHitTestVisible = true;
        _tween?.Stop();
        _tween = new Tween(DispatcherQueue, _translation.Y, 0, 300, Ease.OutCubic,
            v =>
            {
                _translation.Y = v;
                Opacity = Math.Max(0, 1 - v / Height);
            });
    }

    public void Hide()
    {
        IsHitTestVisible = false;
        _tween?.Stop();
        _tween = new Tween(DispatcherQueue, _translation.Y, Height, 260, Ease.Standard,
            v =>
            {
                _translation.Y = v;
                Opacity = Math.Max(0, 1 - v / Height);
            });
    }
}
