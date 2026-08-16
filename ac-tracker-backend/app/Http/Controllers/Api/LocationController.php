<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LocationLog;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Carbon\Carbon;

class LocationController extends Controller
{
    // A point within this radius of the current stay's anchor point is
    // considered "still the same place" rather than a new visit.
    private const STAY_RADIUS_METERS = 150;

    // Stays shorter than this are dropped — usually just GPS noise while
    // driving through, not an actual visit.
    private const MIN_STAY_MINUTES = 5;

    /**
     * Ingest a batch of GPS points from the Flutter background tracker.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'points' => 'required|array|min:1',
            'points.*.latitude' => 'required|numeric|between:-90,90',
            'points.*.longitude' => 'required|numeric|between:-180,180',
            'points.*.recorded_at' => 'required|date',
        ]);

        $rows = array_map(fn ($p) => [
            'latitude' => $p['latitude'],
            'longitude' => $p['longitude'],
            'recorded_at' => $p['recorded_at'],
            'created_at' => now(),
            'updated_at' => now(),
        ], $validated['points']);

        LocationLog::insert($rows);

        return response()->json(['inserted' => count($rows)], 201);
    }

    /**
     * Return a day's activity as a list of "stays": places where the AC
     * remained for a period of time, with the from-to time range.
     */
    public function daySummary(Request $request)
    {
        $date = $request->query('date', now()->toDateString());

        $points = LocationLog::whereDate('recorded_at', $date)
            ->orderBy('recorded_at')
            ->get(['latitude', 'longitude', 'recorded_at']);

        return response()->json([
            'date' => $date,
            'stays' => $this->clusterIntoStays($points),
            'distance_km' => round($this->totalDistanceMeters($points) / 1000, 1),
            'tracked_minutes' => $this->trackedMinutes($points),
            // Raw GPS fixes received today, before clustering/filtering — if
            // this is 0, no pings are arriving at all (permission/stream
            // problem on the phone). If this is >0 but stays is empty, pings
            // are arriving fine and it's just too early for any of them to
            // reach the 5-minute minimum stay duration.
            'raw_point_count' => $points->count(),
        ]);
    }

    private function totalDistanceMeters(Collection $points): float
    {
        $total = 0.0;
        for ($i = 1; $i < count($points); $i++) {
            $total += $this->haversineMeters(
                $points[$i - 1]->latitude,
                $points[$i - 1]->longitude,
                $points[$i]->latitude,
                $points[$i]->longitude
            );
        }
        return $total;
    }

    private function trackedMinutes(Collection $points): int
    {
        if ($points->isEmpty()) {
            return 0;
        }
        $first = Carbon::parse($points->first()->recorded_at);
        $last = Carbon::parse($points->last()->recorded_at);
        return $first->diffInMinutes($last);
    }

    private function clusterIntoStays(Collection $points): array
    {
        $stays = [];
        $current = null;

        foreach ($points as $point) {
            if ($current === null) {
                $current = $this->newStay($point);
                continue;
            }

            $distance = $this->haversineMeters(
                $current['anchor_lat'],
                $current['anchor_lng'],
                $point->latitude,
                $point->longitude
            );

            if ($distance <= self::STAY_RADIUS_METERS) {
                $current['end_time'] = Carbon::parse($point->recorded_at);
            } else {
                $stays[] = $current;
                $current = $this->newStay($point);
            }
        }

        if ($current !== null) {
            $stays[] = $current;
        }

        // Drop very short stays (likely just transit/GPS noise) and format for output.
        return collect($stays)
            ->filter(fn ($s) => $s['start_time']->diffInMinutes($s['end_time']) >= self::MIN_STAY_MINUTES)
            ->map(fn ($s) => [
                'latitude' => $s['anchor_lat'],
                'longitude' => $s['anchor_lng'],
                // TODO: reverse-geocode lat/lng into a readable address here
                // (Google Geocoding API or OSM Nominatim) before returning to the app.
                'from' => $s['start_time']->format('H:i'),
                'to' => $s['end_time']->format('H:i'),
                'duration_minutes' => $s['start_time']->diffInMinutes($s['end_time']),
            ])
            ->values()
            ->all();
    }

    private function newStay($point): array
    {
        return [
            'anchor_lat' => $point->latitude,
            'anchor_lng' => $point->longitude,
            'start_time' => Carbon::parse($point->recorded_at),
            'end_time' => Carbon::parse($point->recorded_at),
        ];
    }

    private function haversineMeters($lat1, $lon1, $lat2, $lon2): float
    {
        $earthRadius = 6371000;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
