namespace Chron.Services;

/// <summary>Global service locator, initialised once at launch.</summary>
public static class AppServices
{
    public static AppSettings Settings { get; private set; } = null!;
    public static PomodoroStore Pomodoro { get; private set; } = null!;

    public static void Initialize()
    {
        Motion.Reduced = !SystemAnimationsEnabled();
        Settings = AppSettings.Load();
        Feedback.SoundEnabled = Settings.SoundEnabled;
        Pomodoro = PomodoroStore.Load();
    }

    private static bool SystemAnimationsEnabled()
    {
        try
        {
            return new Windows.UI.ViewManagement.UISettings().AnimationsEnabled;
        }
        catch
        {
            return true;
        }
    }
}
