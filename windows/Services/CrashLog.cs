namespace Chron.Services;

/// <summary>Append-only crash log, written next to the app data folder.</summary>
public static class CrashLog
{
    public static void Record(string source, Exception? ex)
    {
        try
        {
            Directory.CreateDirectory(LocalStore.Folder);
            var line = $"[{DateTime.Now:O}] {source}: {ex}{Environment.NewLine}";
            File.AppendAllText(Path.Combine(LocalStore.Folder, "chron.log"), line);
        }
        catch
        {
            // logging must never throw
        }
    }
}
