using Chron.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace Chron.Controls;

/// <summary>Hours / minutes / seconds wheel used to set the countdown duration.</summary>
public sealed class DurationWheel : Grid
{
    private readonly WheelColumn _hours = new() { Min = 0, Max = 23 };
    private readonly WheelColumn _minutes = new() { Min = 0, Max = 59 };
    private readonly WheelColumn _seconds = new() { Min = 0, Max = 59 };

    public event Action<int>? Changed;

    public DurationWheel()
    {
        Height = 220;
        ColumnSpacing = 10;
        for (var i = 0; i < 3; i++)
            ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        RowDefinitions.Add(new RowDefinition { Height = new GridLength(28) });

        AddColumn(_hours, 0, "hours");
        AddColumn(_minutes, 1, "min");
        AddColumn(_seconds, 2, "sec");

        _hours.ValueCommitted += _ => Raise();
        _minutes.ValueCommitted += _ => Raise();
        _seconds.ValueCommitted += _ => Raise();
    }

    public int TotalSeconds => _hours.Value * 3600 + _minutes.Value * 60 + _seconds.Value;

    public void SetSeconds(int total)
    {
        total = Math.Max(0, total);
        _hours.SetValue(total / 3600, false);
        _minutes.SetValue(total % 3600 / 60, false);
        _seconds.SetValue(total % 60, false);
    }

    private void Raise() => Changed?.Invoke(TotalSeconds);

    private void AddColumn(WheelColumn wheel, int column, string label)
    {
        SetColumn(wheel, column);
        Children.Add(wheel);
        var text = Typo.Label(label, 12, Palette.InkFaint);
        text.VerticalAlignment = VerticalAlignment.Center;
        SetColumn(text, column);
        SetRow(text, 1);
        Children.Add(text);
    }
}
