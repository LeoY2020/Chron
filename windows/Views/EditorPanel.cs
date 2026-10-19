using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Chron.Views;

/// <summary>In-place editor: font colour swatches plus an optional thickness slider.</summary>
public sealed class EditorPanel : Grid
{
    private readonly TranslateTransform _translation = new();
    private readonly Color _startInk;
    private Tween? _tween;
    private Color _ink;
    private double _thickness;

    public event Action<Color, double>? Changed;

    public EditorPanel(bool supportsThickness, Color ink, double thickness)
    {
        _ink = ink;
        _thickness = thickness;
        RenderTransform = _translation;
        Visibility = Visibility.Collapsed;
        Opacity = 0;
        _startInk = ink;

        var card = new Border
        {
            Background = new SolidColorBrush(Color.FromArgb(235, 28, 28, 30)),
            CornerRadius = new CornerRadius(18),
            Padding = new Thickness(16, 12, 16, 12),
            BorderThickness = new Thickness(1),
            BorderBrush = new SolidColorBrush(Color.FromArgb(24, 255, 255, 255)),
        };
        var stack = new StackPanel { Spacing = 10 };
        card.Child = stack;
        Children.Add(card);

        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 10,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        var colors = new[]
        {
            Palette.Ink, Palette.InkDim, Palette.Orange, Palette.Amber, Palette.Teal,
            Color.FromArgb(255, 120, 170, 255), Color.FromArgb(255, 255, 105, 120),
        };
        foreach (var color in colors)
        {
            var captured = color;
            var dot = new Button
            {
                Width = 26,
                Height = 26,
                Padding = new Thickness(0),
                CornerRadius = new CornerRadius(13),
                Background = new SolidColorBrush(captured),
                BorderThickness = new Thickness(0),
                ElementSoundMode = ElementSoundMode.Off,
            };
            dot.Click += (_, _) =>
            {
                Feedback.Light();
                Motion.Pulse(dot);
                _ink = captured;
                Changed?.Invoke(_ink, _thickness);
            };
            row.Children.Add(dot);
        }
        stack.Children.Add(row);

        if (supportsThickness)
        {
            var slider = new Slider
            {
                Minimum = 3,
                Maximum = 26,
                Value = thickness,
                Width = 220,
                StepFrequency = 1,
            };
            slider.ValueChanged += (_, e) =>
            {
                _thickness = e.NewValue;
                Changed?.Invoke(_ink, _thickness);
            };
            stack.Children.Add(slider);
        }
    }

    public void Show()
    {
        Visibility = Visibility.Visible;
        _tween?.Stop();
        _tween = new Tween(DispatcherQueue, 18, 0, 260, Ease.OutCubic, v =>
        {
            _translation.Y = v;
            Opacity = Math.Max(0, 1 - v / 18);
        });
    }

    public void Hide()
    {
        if (Visibility == Visibility.Collapsed)
            return;
        _tween?.Stop();
        _tween = new Tween(DispatcherQueue, _translation.Y, 18, 180, Ease.Standard, v =>
        {
            _translation.Y = v;
            Opacity = Math.Max(0, 1 - v / 18);
        }, () => Visibility = Visibility.Collapsed);
    }
}
