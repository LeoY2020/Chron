using System.Linq;

namespace Chron.Services;

public sealed class FocusSession
{
    public DateTime Start { get; set; }
    public int Minutes { get; set; }
    public bool Completed { get; set; }
    public bool Break { get; set; }
}

/// <summary>Pomodoro session history, persisted as JSON.</summary>
public sealed class PomodoroStore
{
    private const string FileName = "pomodoro-sessions.json";
    private const int Cap = 500;

    public List<FocusSession> Sessions { get; set; } = new();

    public static PomodoroStore Load() => LocalStore.Load(FileName, new PomodoroStore());

    public void Save() => LocalStore.Save(FileName, this);

    public void Add(FocusSession s)
    {
        Sessions.Add(s);
        if (Sessions.Count > Cap)
            Sessions.RemoveRange(0, Sessions.Count - Cap);
        Save();
    }

    private IEnumerable<FocusSession> Focuses => Sessions.Where(s => s.Completed && !s.Break);

    public int TodayCount => Focuses.Count(s => s.Start.Date == DateTime.Today);

    public int TodayMinutes => Focuses.Where(s => s.Start.Date == DateTime.Today).Sum(s => s.Minutes);

    public int WeekCount => Focuses.Count(s => s.Start.Date >= DateTime.Today.AddDays(-6));

    public int WeekMinutes => Focuses.Where(s => s.Start.Date >= DateTime.Today.AddDays(-6)).Sum(s => s.Minutes);

    /// <summary>Focus minutes for the last 7 days, oldest first.</summary>
    public int[] Last7Minutes()
    {
        var result = new int[7];
        for (var i = 0; i < 7; i++)
        {
            var day = DateTime.Today.AddDays(i - 6);
            result[i] = Focuses.Where(s => s.Start.Date == day).Sum(s => s.Minutes);
        }
        return result;
    }
}
