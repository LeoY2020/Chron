using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Media;
using Windows.UI;
using Windows.UI.Text;

namespace Chron.Services;

/// <summary>Segoe UI Variable typography with tabular figures (digits never jitter).</summary>
public static class Typo
{
    public static readonly FontFamily Text = new("Segoe UI Variable Text");
    public static readonly FontFamily Display = new("Segoe UI Variable Display");

    /// <summary>A tabular-figure text block used for every clock/countdown digit.</summary>
    public static TextBlock Digits(string text, double size, Color color, FontWeight? weight = null)
    {
        var tb = new TextBlock
        {
            Text = text,
            FontFamily = Display,
            FontSize = size,
            Foreground = new SolidColorBrush(color),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            TextWrapping = TextWrapping.NoWrap,
        };
        if (weight is { } w)
            tb.FontWeight = w;
        Typography.SetNumeralAlignment(tb, FontNumeralAlignment.Tabular);
        return tb;
    }

    public static TextBlock Label(string text, double size, Color color)
    {
        var tb = new TextBlock
        {
            Text = text,
            FontFamily = Text,
            FontSize = size,
            Foreground = new SolidColorBrush(color),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
        Typography.SetNumeralAlignment(tb, FontNumeralAlignment.Tabular);
        return tb;
    }
}
