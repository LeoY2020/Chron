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

        Children.Add(_row);
    }

    public void SetItems(IReadOnlyList<string> names, int selected)
    {
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
                Background = new SolidColorBrush(selected == i
                    ? Color.FromArgb(38, 255, 255, 255)
                    : Color.FromArgb(16, 255, 255, 255)),
                ElementSoundMode = ElementSoundMode.Off,
            };
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

    public void SetSelected(int selected)
    {
        for (var i = 0; i < _buttons.Count; i++)
        {
            _buttons[i].Background = new SolidColorBrush(selected == i
                ? Color.FromArgb(38, 255, 255, 255)
                : Color.FromArgb(16, 255, 255, 255));
            if (_buttons[i].Content is TextBlock tb)
                tb.Foreground = new SolidColorBrush(selected == i ? Palette.Ink : Palette.InkDim);
        }
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
