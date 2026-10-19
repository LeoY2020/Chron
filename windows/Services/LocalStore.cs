using System.Text.Json;

namespace Chron.Services;

/// <summary>
/// Local persistence. Prefers ApplicationData.LocalFolder (packaged runs) and
/// degrades to %LOCALAPPDATA%\Chron when unpackaged (WindowsPackageType=None).
/// </summary>
public static class LocalStore
{
    private static string? _folder;

    public static string Folder => _folder ??= Resolve();

    private static string Resolve()
    {
        try
        {
            var p = Windows.Storage.ApplicationData.Current.LocalFolder.Path;
            if (!string.IsNullOrEmpty(p))
                return p;
        }
        catch
        {
            // unpackaged: ApplicationData is unavailable
        }
        return Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Chron");
    }

    public static T Load<T>(string fileName, T fallback)
    {
        try
        {
            var path = Path.Combine(Folder, fileName);
            if (!File.Exists(path))
                return fallback;
            var json = File.ReadAllText(path);
            var value = JsonSerializer.Deserialize<T>(json);
            return value is null ? fallback : value;
        }
        catch
        {
            return fallback;
        }
    }

    public static void Save<T>(string fileName, T value)
    {
        try
        {
            Directory.CreateDirectory(Folder);
            var path = Path.Combine(Folder, fileName);
            var json = JsonSerializer.Serialize(value, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(path, json);
        }
        catch
        {
            // persistence failure must never crash the app
        }
    }
}
