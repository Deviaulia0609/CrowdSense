<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Stock;
use App\Models\Topic;
use App\Services\ActivityService;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Mengirim data mentah: aktivitas per saham + banyak alert.
     * Perangkat yang menghitung tren (EWMA), skor relevansi (WSM) dan top-5 (heap).
     */
    public function index(ActivityService $activity)
    {
        $series = $activity->series();
        $names = Stock::whereIn('code', array_keys($series))->pluck('name', 'code');

        $trending = collect($series)
            ->map(fn ($s, $code) => [
                'code' => $code,
                'name' => $names[$code] ?? $code,
                'series' => $s,
                'total' => array_sum($s),
            ])
            ->sortByDesc('total')->values()->take(20);

        $alerts = Topic::query()
            ->where('last_report_at', '>=', now()->subDay())
            ->withCount([
                'reports',
                'reports as source_count' => fn ($q) => $q->select(DB::raw('count(distinct source_category)')),
            ])
            ->orderByDesc('last_report_at')
            ->limit(100)
            ->get()
            ->map(fn ($t) => [
                'topic_id' => $t->id,
                'title' => $t->title,
                'tickers' => $t->tickers,
                'report_count' => $t->reports_count,
                'source_count' => (int) $t->source_count,
                'status' => $t->status,
                'last_report_at' => $t->last_report_at,
            ])->values();

        return response()->json(['trending' => $trending, 'alerts' => $alerts]);
    }
}
