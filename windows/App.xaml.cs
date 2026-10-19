using Chron.Services;
using Chron.Views;
using Microsoft.UI.Xaml;

namespace Chron;

public partial class App : Application
{
    /// <summary>Live main window reference (kept for dialogs / future use).</summary>
    public static MainWindow Window { get; private set; } = null!;

    public App()
    {
        InitializeComponent();
        UnhandledException += (_, e) => CrashLog.Record("ui", e.Exception);
        AppDomain.CurrentDomain.UnhandledException +=
            (_, e) => CrashLog.Record("appdomain", e.ExceptionObject as Exception);
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        AppServices.Initialize();
        Window = new MainWindow();
        Window.Activate();
    }
}
