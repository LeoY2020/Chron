using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Chron.Services;

/// <summary>
/// Desktop degradation of haptics: a graded, quiet system sound plus an optional
/// micro scale pulse. Never forces vibration; respects the system sound toggle.
/// </summary>
public static class Feedback
{
    public static bool SoundEnabled { get; set; } = true;

    /// <summary>Light: style switch, wheel snap, passing a tick, entering an editor.</summary>
    public static void Light() => Play(ElementSoundKind.Focus, 0.28);

    /// <summary>Medium: long-press, start/pause, pull-down summary.</summary>
    public static void Medium() => Play(ElementSoundKind.MoveNext, 0.40);

    /// <summary>Heavy: focus round complete, countdown reaching zero.</summary>
    public static void Heavy() => Play(ElementSoundKind.Show, 0.55);

    private static void Play(ElementSoundKind kind, double volume)
    {
        if (!SoundEnabled)
            return;
        try
        {
            if (ElementSoundPlayer.State == ElementSoundPlayerState.Off)
                return;
            ElementSoundPlayer.Volume = volume;
            ElementSoundPlayer.Play(kind);
        }
        catch
        {
            // no audio device / sound disabled at OS level
        }
    }

    /// <summary>Subtle visual micro-motion paired with the sound cue.</summary>
    public static void Pulse(UIElement element, float to = 0.96f, double ms = 130)
        => Motion.Pulse(element, to, ms);
}
