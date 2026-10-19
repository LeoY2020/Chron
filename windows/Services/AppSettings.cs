namespace Chron.Services;

/// <summary>User settings. Persisted as JSON (LocalSettings equivalent).</summary>
public sealed class AppSettings
{
    private const string FileName = "settings.json";

    // Countdown
    public int CountdownStyle { get; set; }
    public int CountdownInk { get; set; } = unchecked((int)0xFFF5F5F7);
    public double RingThickness { get; set; } = 10;
    public int CountdownSeconds { get; set; } = 300;

    // Clock
    public int ClockStyle { get; set; }
    public int ClockInk { get; set; } = unchecked((int)0xFFF5F5F7);

    // Pomodoro
    public int FocusMinutes { get; set; } = 25;
    public int BreakMinutes { get; set; } = 5;

    // Feedback
    public bool SoundEnabled { get; set; } = true;

    public static AppSettings Load() => LocalStore.Load(FileName, new AppSettings());

    public void Save() => LocalStore.Save(FileName, this);
}
