using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Windows.Foundation;
using Windows.UI;

namespace Chron.Views;

/// <summary>Retro seven-segment display composed of polygons. Retro, not cheap.</summary>
public sealed class SevenSegment : Grid
{
    private static readonly int[] Masks =
    {
        63, 6, 91, 79, 102, 109, 125, 7, 127, 111,
    };

    private readonly SegDigit[] _digits = new SegDigit[6];
    private readonly SegColon[] _colons = new SegColon[2];

    public SevenSegment()
    {
        var on = new SolidColorBrush(Color.FromArgb(255, 255, 176, 92));
        var off = new SolidColorBrush(Color.FromArgb(26, 255, 176, 92));

        var row = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 10,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
        for (var i = 0; i < 6; i++)
            _digits[i] = new SegDigit(on, off);
        for (var i = 0; i < 2; i++)
            _colons[i] = new SegColon(on);

        row.Children.Add(_digits[0]);
        row.Children.Add(_digits[1]);
        row.Children.Add(_colons[0]);
        row.Children.Add(_digits[2]);
        row.Children.Add(_digits[3]);
        row.Children.Add(_colons[1]);
        row.Children.Add(_digits[4]);
        row.Children.Add(_digits[5]);

        Children.Add(new Viewbox
        {
            Child = row,
            Stretch = Stretch.Uniform,
            Margin = new Thickness(40, 60, 40, 60),
        });
    }

    /// <summary>Accepts "HH:mm:ss".</summary>
    public void SetTime(string text)
    {
        var digits = new List<int>();
        foreach (var c in text)
            if (char.IsDigit(c))
                digits.Add(c - '0');
        if (digits.Count < 6)
            return;
        for (var i = 0; i < 6; i++)
            _digits[i].Set(Masks[digits[i]]);
    }

    private sealed class SegDigit : Grid
    {
        private const double W = 100;
        private const double H = 180;
        private const double T = 16;

        private readonly Polygon[] _segments = new Polygon[7];
        private readonly Brush _on;
        private readonly Brush _off;

        public SegDigit(Brush on, Brush off)
        {
            _on = on;
            _off = off;
            Width = W;
            Height = H;

            _segments[0] = Horizontal(0, 0, W);
            _segments[1] = Vertical(W - T, 0, H / 2);
            _segments[2] = Vertical(W - T, H / 2, H / 2);
            _segments[3] = Horizontal(0, H - T, W);
            _segments[4] = Vertical(0, H / 2, H / 2);
            _segments[5] = Vertical(0, 0, H / 2);
            _segments[6] = Horizontal(0, H / 2 - T / 2, W);

            foreach (var segment in _segments)
                Children.Add(segment);
        }

        public void Set(int mask)
        {
            for (var i = 0; i < 7; i++)
                _segments[i].Fill = (mask & (1 << i)) != 0 ? _on : _off;
        }

        private static Polygon Horizontal(double x, double y, double width)
        {
            var p = new Polygon();
            p.Points.Add(new Point(x, y + T / 2));
            p.Points.Add(new Point(x + T / 2, y));
            p.Points.Add(new Point(x + width - T / 2, y));
            p.Points.Add(new Point(x + width, y + T / 2));
            p.Points.Add(new Point(x + width - T / 2, y + T));
            p.Points.Add(new Point(x + T / 2, y + T));
            return p;
        }

        private static Polygon Vertical(double x, double y, double height)
        {
            var p = new Polygon();
            p.Points.Add(new Point(x, y + T / 2));
            p.Points.Add(new Point(x + T / 2, y));
            p.Points.Add(new Point(x + T, y + T / 2));
            p.Points.Add(new Point(x + T, y + height - T / 2));
            p.Points.Add(new Point(x + T / 2, y + height));
            p.Points.Add(new Point(x, y + height - T / 2));
            return p;
        }
    }

    private sealed class SegColon : Grid
    {
        public SegColon(Brush brush)
        {
            Width = 24;
            Height = 180;
            var top = new Rectangle
            {
                Width = 16,
                Height = 16,
                RadiusX = 2,
                RadiusY = 2,
                Fill = brush,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                Margin = new Thickness(0, 52, 0, 0),
            };
            var bottom = new Rectangle
            {
                Width = 16,
                Height = 16,
                RadiusX = 2,
                RadiusY = 2,
                Fill = brush,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                Margin = new Thickness(0, 112, 0, 0),
            };
            Children.Add(top);
            Children.Add(bottom);
        }
    }
}
