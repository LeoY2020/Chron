using Chron.Controls;
using Chron.Services;
using Microsoft.UI.Windowing;
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
    private readonly List<Grid> _dotHosts = new();
    private readonly List<Border> _dotShapes = new();
    private Tween? _dotTween;
    private int _hoverDot = -1;
    private bool _fullScreen;
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
        _countdown.PagingLockChanged += locked => SetLocked(locked);
        _clock.PagingLockChanged += locked => SetLocked(locked);

        Host.Children.Add(_pager);
        BuildDots();
        Host.Children.Add(_dots);

        SetupShortcuts();
        UpdateDots();
    }

    /// <summary>收缩态锁定翻页，同时淡出页面指示器。</summary>
    private void SetLocked(bool locked)
    {
        _pager.IsPagingEnabled = !locked;
        // 收缩态下指示器不再有意义，淡出避免与样式栏争夺注意力。
        _dotTween?.Stop();
        _dotTween = new Tween(DispatcherQueue, _dots.Opacity, locked ? 0 : 1, 220, Ease.Standard,
            v => _dots.Opacity = v);
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
        AddAccelerator(VirtualKey.Left, () =>
        {
            if (_pager.IsPagingEnabled)
                _pager.Previous();
        });

        AddAccelerator(VirtualKey.Right, () =>
        {
            if (_pager.IsPagingEnabled)
                _pager.Next();
        });

        AddAccelerator(VirtualKey.Space, PrimaryAction);
        AddAccelerator(VirtualKey.R, ResetCurrentPage);

        // 数字键直达三页（桌面端的“跳转”心智）。
        AddAccelerator(VirtualKey.Number1, () => JumpTo(0));
        AddAccelerator(VirtualKey.Number2, () => JumpTo(1));
        AddAccelerator(VirtualKey.Number3, () => JumpTo(2));

        AddAccelerator(VirtualKey.Escape, () =>
        {
            if (!CloseOverlay() && _fullScreen)
                ToggleFullscreen();
        });
        AddAccelerator(VirtualKey.F11, ToggleFullscreen);
    }

    private void AddAccelerator(VirtualKey key, Action action)
    {
        var accelerator = new KeyboardAccelerator { Key = key };
        accelerator.Invoked += (_, e) =>
        {
            action();
            e.Handled = true;
        };
        Root.KeyboardAccelerators.Add(accelerator);
    }

    private void JumpTo(int index)
    {
        if (!_pager.IsPagingEnabled)
            return;
        _pager.GoTo(index);
    }

    private void ResetCurrentPage()
    {
        switch (_pager.CurrentIndex)
        {
            case 0:
                _countdown.ResetToDuration();
                break;
            case 1:
                _pomodoro.ResetPhase();
                break;
        }
    }

    /// <summary>Esc 分级退出：当前页先收起编辑器 / 收缩态。</summary>
    private bool CloseOverlay()
    {
        return _pager.CurrentIndex switch
        {
            0 => _countdown.CloseOverlay(),
            2 => _clock.CloseOverlay(),
            _ => false,
        };
    }

    private void ToggleFullscreen()
    {
        try
        {
            AppWindow.SetPresenter(_fullScreen
                ? AppWindowPresenterKind.Overlapped
                : AppWindowPresenterKind.FullScreen);
            _fullScreen = !_fullScreen;
        }
        catch
        {
            // 部分系统版本不支持运行时切换 presenter
        }
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
            var index = i;
            var dot = new Border
            {
                Width = 5,
                Height = 5,
                CornerRadius = new CornerRadius(2.5),
                Background = new SolidColorBrush(Palette.InkFaint),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            };

            // 22×22 热区：小圆点也能稳稳点中。
            var host = new Grid { Width = 22, Height = 22, Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent) };
            host.Children.Add(dot);
            host.PointerEntered += (_, _) => SetHoverDot(index);
            host.PointerExited += (_, _) => SetHoverDot(-1);
            host.PointerPressed += (_, _) => JumpTo(index);

            _dotHosts.Add(host);
            _dotShapes.Add(dot);
            _dots.Children.Add(host);
        }
    }

    private void SetHoverDot(int index)
    {
        _hoverDot = index;
        UpdateDots();
    }

    private void UpdateDots()
    {
        for (var i = 0; i < _dotShapes.Count; i++)
        {
            var dot = _dotShapes[i];
            var active = i == _pager.CurrentIndex;
            var hovered = i == _hoverDot;
            dot.Width = active ? 14 : (hovered ? 7 : 5);
            dot.Height = active ? 5 : (hovered ? 7 : 5);
            dot.CornerRadius = new CornerRadius(dot.Height / 2);
            dot.Background = new SolidColorBrush(active ? Palette.InkDim : Palette.InkFaint);
            dot.Opacity = active || hovered ? 1 : 0.85;
        }
    }
}
