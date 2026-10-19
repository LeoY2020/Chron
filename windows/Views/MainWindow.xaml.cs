using Chron.Controls;
using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.System;

namespace Chron.Views;

/// <summary>
/// Main window: a 40 px drag strip over a full-screen horizontal pager hosting
/// the Countdown, Pomodoro and Clock pages, plus a minimal page indicator.
/// </summary>
public sealed partial class MainWindow : Window
{
    private readonly PagingView _pager = new();
    private readonly StackPanel _dots = new()
    {
        Orientation = Orientation.Horizontal,
        Spacing = 8,
        HorizontalAlignment = HorizontalAlignment.Center,
        VerticalAlignment = VerticalAlignment.Bottom,
        Margin = new Thickness(0, 0, 0, 16),
    };
    private readonly List<Ellipse> _dotShapes = new();
    private readonly CountdownPage _countdown = new();
    private readonly PomodoroPage _pomodoro = new();
    private readonly ClockPage _clock = new();

    public MainWindow()
    {
        InitializeComponent();
        Title = "Chron";
        Root.RequestedTheme = ElementTheme.Dark;

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(TitleDrag);
        ConfigureWindow();
        ConfigureTitleBar();

        _pager.AddPage(_countdown);
        _pager.AddPage(_pomodoro);
        _pager.AddPage(_clock);
        _pager.IndexChanged += _ => UpdateDots();
        _countdown.PagingLockChanged += locked => _pager.IsPagingEnabled = !locked;
        _clock.PagingLockChanged += locked => _pager.IsPagingEnabled = !locked;

        Host.Children.Add(_pager);
        BuildDots();
        Host.Children.Add(_dots);

        SetupShortcuts();
        UpdateDots();
    }

    private void ConfigureWindow()
    {
        AppWindow.Resize(new Windows.Graphics.SizeInt32(900, 600));
        AppWindow.Changed += (_, args) =>
        {
            if (!args.DidSizeChange)
                return;
            var size = AppWindow.Size;
            var width = Math.Max(480, size.Width);
            var height = Math.Max(360, size.Height);
            if (width != size.Width || height != size.Height)
                AppWindow.Resize(new Windows.Graphics.SizeInt32(width, height));
        };
    }

    private void ConfigureTitleBar()
    {
        try
        {
            var bar = AppWindow.TitleBar;
            bar.ButtonBackgroundColor = Windows.UI.Color.FromArgb(0, 0, 0, 0);
            bar.ButtonInactiveBackgroundColor = Windows.UI.Color.FromArgb(0, 0, 0, 0);
            bar.ButtonForegroundColor = Windows.UI.Color.FromArgb(255, 200, 200, 205);
            bar.ButtonInactiveForegroundColor = Windows.UI.Color.FromArgb(255, 120, 120, 125);
            bar.ButtonHoverBackgroundColor = Windows.UI.Color.FromArgb(24, 255, 255, 255);
            bar.ButtonHoverForegroundColor = Windows.UI.Color.FromArgb(255, 255, 255, 255);
            bar.ButtonPressedBackgroundColor = Windows.UI.Color.FromArgb(40, 255, 255, 255);
            bar.ButtonPressedForegroundColor = Windows.UI.Color.FromArgb(255, 255, 255, 255);
        }
        catch
        {
            // title-bar colour APIs are unavailable on older builds
        }
    }

    private void SetupShortcuts()
    {
        var previous = new KeyboardAccelerator { Key = VirtualKey.Left };
        previous.Invoked += (_, e) =>
        {
            if (_pager.IsPagingEnabled)
            {
                _pager.Previous();
                e.Handled = true;
            }
        };

        var next = new KeyboardAccelerator { Key = VirtualKey.Right };
        next.Invoked += (_, e) =>
        {
            if (_pager.IsPagingEnabled)
            {
                _pager.Next();
                e.Handled = true;
            }
        };

        var space = new KeyboardAccelerator { Key = VirtualKey.Space };
        space.Invoked += (_, e) =>
        {
            PrimaryAction();
            e.Handled = true;
        };

        Root.KeyboardAccelerators.Add(previous);
        Root.KeyboardAccelerators.Add(next);
        Root.KeyboardAccelerators.Add(space);
    }

    private void PrimaryAction()
    {
        if (!_pager.IsPagingEnabled)
            return;
        switch (_pager.CurrentIndex)
        {
            case 0:
                _countdown.PrimaryAction();
                break;
            case 1:
                _pomodoro.PrimaryAction();
                break;
        }
    }

    private void BuildDots()
    {
        for (var i = 0; i < 3; i++)
        {
            var dot = new Ellipse { Width = 6, Height = 6 };
            _dotShapes.Add(dot);
            _dots.Children.Add(dot);
        }
    }

    private void UpdateDots()
    {
        for (var i = 0; i < _dotShapes.Count; i++)
        {
            _dotShapes[i].Fill = new SolidColorBrush(
                i == _pager.CurrentIndex ? Palette.InkDim : Palette.InkFaint);
        }
    }
}
