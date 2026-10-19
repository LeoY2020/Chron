using System.Numerics;
using Microsoft.UI.Composition;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Hosting;
using Microsoft.UI.Xaml.Media;
using Windows.Foundation;

namespace Chron.Services;

/// <summary>Easing curves for the whole project. Default: cubic-bezier(0.4, 0, 0.2, 1).</summary>
public static class Ease
{
    public static readonly Func<double, double> Standard = CubicBezier(0.4, 0.0, 0.2, 1.0);

    public static readonly Func<double, double> OutCubic =
        t => 1.0 - Math.Pow(1.0 - t, 3);

    public static readonly Func<double, double> OutBack = t =>
    {
        const double c1 = 1.70158;
        const double c3 = c1 + 1;
        return 1 + c3 * Math.Pow(t - 1, 3) + c1 * Math.Pow(t - 1, 2);
    };

    public static readonly Func<double, double> InOutQuad =
        t => t < 0.5 ? 2 * t * t : 1 - Math.Pow(-2 * t + 2, 2) / 2;

    /// <summary>Standard CSS-style cubic-bezier sampler (x1..y2 in 0..1).</summary>
    public static Func<double, double> CubicBezier(double x1, double y1, double x2, double y2)
    {
        static double Curve(double u, double p1, double p2)
            => 3 * (1 - u) * (1 - u) * u * p1 + 3 * (1 - u) * u * u * p2 + u * u * u;

        static double Slope(double u, double p1, double p2)
            => 3 * (1 - u) * (1 - u) * p1 + 6 * (1 - u) * u * (p2 - p1) + 3 * u * u * (1 - p2);

        return t =>
        {
            if (t <= 0) return 0;
            if (t >= 1) return 1;
            var u = t;
            for (var i = 0; i < 8; i++)
            {
                var d = Slope(u, x1, x2);
                if (Math.Abs(d) < 1e-6)
                    break;
                var x = Curve(u, x1, x2) - t;
                u -= x / d;
                u = Math.Clamp(u, 0, 1);
            }
            return Curve(u, y1, y2);
        };
    }
}

/// <summary>
/// One-shot property animation driven by a DispatcherQueueTimer (~60 fps).
/// Deterministic and safe for unpackaged WinUI 3 where Storyboard targets are fragile.
/// </summary>
public sealed class Tween
{
    private readonly DispatcherQueueTimer _timer;
    private readonly double _from;
    private readonly double _to;
    private readonly double _durationMs;
    private readonly Func<double, double> _ease;
    private readonly Action<double> _apply;
    private readonly Action? _done;
    private readonly long _startTicks;
    private bool _finished;

    public Tween(DispatcherQueue queue, double from, double to, double durationMs,
                 Func<double, double> ease, Action<double> apply, Action? done = null)
    {
        _from = from;
        _to = to;
        _durationMs = Math.Max(1, durationMs);
        _ease = ease;
        _apply = apply;
        _done = done;

        if (Motion.Reduced)
        {
            _apply(_to);
            _finished = true;
            _done?.Invoke();
            return;
        }

        _apply(_from);
        _startTicks = Environment.TickCount64;
        _timer = queue.CreateTimer();
        _timer.Interval = TimeSpan.FromMilliseconds(15);
        _timer.IsRepeating = true;
        _timer.Tick += OnTick;
        _timer.Start();
    }

    private void OnTick(DispatcherQueueTimer sender, object args)
    {
        var p = (Environment.TickCount64 - _startTicks) / _durationMs;
        if (p >= 1)
            p = 1;
        _apply(_from + (_to - _from) * _ease(p));
        if (p >= 1)
            Finish();
    }

    private void Finish()
    {
        if (_finished)
            return;
        _finished = true;
        _timer.Stop();
        _timer.Tick -= OnTick;
        _done?.Invoke();
    }

    /// <summary>Cancel without invoking the completion callback.</summary>
    public void Stop()
    {
        if (_finished || _timer is null)
            return;
        _finished = true;
        _timer.Stop();
        _timer.Tick -= OnTick;
    }
}

/// <summary>Global motion helpers.</summary>
public static class Motion
{
    /// <summary>Set from the OS "reduce motion" accessibility setting.</summary>
    public static bool Reduced { get; set; }

    /// <summary>Composition-driven micro scale pulse (squash), paired with sound.</summary>
    public static void Pulse(UIElement element, float to = 0.96f, double ms = 130)
    {
        if (Reduced || element is null)
            return;
        try
        {
            var visual = ElementCompositionPreview.GetElementVisual(element);
            var compositor = visual.Compositor;
            visual.CenterPoint = new Vector3(element.ActualSize.X / 2f, element.ActualSize.Y / 2f, 0f);
            var scale = compositor.CreateVector2KeyFrameAnimation();
            scale.InsertKeyFrame(0f, Vector2.One);
            scale.InsertKeyFrame(0.45f, new Vector2(to, to));
            scale.InsertKeyFrame(1f, Vector2.One);
            scale.Duration = TimeSpan.FromMilliseconds(ms);
            visual.StartAnimation("Scale", scale);
        }
        catch
        {
            // visual not yet realised
        }
    }
}

/// <summary>Geometry helpers — arcs and sectors used by the drawn styles.</summary>
public static class Geo
{
    private static Point OnCircle(double cx, double cy, double r, double degrees)
    {
        var rad = (degrees - 90) * Math.PI / 180.0;
        return new Point(cx + r * Math.Cos(rad), cy + r * Math.Sin(rad));
    }

    /// <summary>Open arc from 12 o'clock, sweeping clockwise by <paramref name="sweepDeg"/>.</summary>
    public static PathGeometry Arc(double cx, double cy, double r, double sweepDeg)
    {
        var sweep = Math.Clamp(sweepDeg, 0.01, 359.99);
        var figure = new PathFigure
        {
            StartPoint = OnCircle(cx, cy, r, 0),
            IsClosed = false,
            IsFilled = false,
        };
        figure.Segments.Add(new ArcSegment
        {
            Point = OnCircle(cx, cy, r, sweep),
            Size = new Size(r, r),
            IsLargeArc = sweep > 180,
            SweepDirection = SweepDirection.Clockwise,
        });
        var geo = new PathGeometry();
        geo.Figures.Add(figure);
        return geo;
    }

    /// <summary>Filled pie sector from 12 o'clock, sweeping clockwise.</summary>
    public static PathGeometry Sector(double cx, double cy, double r, double sweepDeg)
    {
        var sweep = Math.Clamp(sweepDeg, 0.01, 359.99);
        var figure = new PathFigure
        {
            StartPoint = new Point(cx, cy),
            IsClosed = true,
            IsFilled = true,
        };
        figure.Segments.Add(new LineSegment { Point = OnCircle(cx, cy, r, 0) });
        figure.Segments.Add(new ArcSegment
        {
            Point = OnCircle(cx, cy, r, sweep),
            Size = new Size(r, r),
            IsLargeArc = sweep > 180,
            SweepDirection = SweepDirection.Clockwise,
        });
        var geo = new PathGeometry();
        geo.Figures.Add(figure);
        return geo;
    }
}
