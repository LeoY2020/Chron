using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Chron.Services;

/// <summary>Shared dark palette and colour helpers. Dark-dominant, quiet.</summary>
public static class Palette
{
    // Backgrounds
    public static readonly Color Bg = Color.FromArgb(255, 10, 10, 12);
    public static readonly Color BgPure = Color.FromArgb(255, 0, 0, 0);
    public static readonly Color PomodoroBg = Color.FromArgb(255, 26, 17, 11);
    public static readonly Color PomodoroBreakBg = Color.FromArgb(255, 12, 20, 18);

    // Ink
    public static readonly Color Ink = Color.FromArgb(255, 245, 245, 247);
    public static readonly Color InkDim = Color.FromArgb(255, 142, 142, 147);
    public static readonly Color InkFaint = Color.FromArgb(255, 84, 84, 88);

    // Accents
    public static readonly Color Orange = Color.FromArgb(255, 255, 149, 0);
    public static readonly Color OrangeDeep = Color.FromArgb(255, 255, 94, 0);
    public static readonly Color Amber = Color.FromArgb(255, 255, 196, 87);
    public static readonly Color Teal = Color.FromArgb(255, 90, 200, 190);

    public static Color FromArgb(int argb) =>
        Color.FromArgb((byte)((argb >> 24) & 0xFF), (byte)((argb >> 16) & 0xFF),
                       (byte)((argb >> 8) & 0xFF), (byte)(argb & 0xFF));

    public static int ToArgb(Color c) => (c.A << 24) | (c.R << 16) | (c.G << 8) | c.B;

    public static Color Mix(Color a, Color b, double t)
    {
        t = Math.Clamp(t, 0, 1);
        return Color.FromArgb(
            (byte)(a.A + (b.A - a.A) * t),
            (byte)(a.R + (b.R - a.R) * t),
            (byte)(a.G + (b.G - a.G) * t),
            (byte)(a.B + (b.B - a.B) * t));
    }

    public static SolidColorBrush Brush(Color c) => new(c);
}
