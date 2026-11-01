<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Stock;
use App\Models\Topic;
use App\Services\ActivityService;
use Illuminate\Support\Facades\DB;

class StockController extends Controller
{
    public function index()
    {
        return Stock::orderBy('code')->get(['code', 'name']);
    }

    public function show(string $code, ActivityService $activity)
    {
        $stock = Stock::findOrFail(strtoupper($code));
        $series = $activity->series([$stock->code])[$stock->code] ?? [0, 0, 0, 0, 0];

        $topics = Topic::whereHas('reports.stocks', fn ($q) => $q->where('stocks.code', $stock->code))
            ->withCount([
                'reports',
                'reports as source_count' => fn ($q) => $q->select(DB::raw('count(distinct source_category)')),
            ])
            ->orderByDesc('last_report_at')
            ->limit(20)
            ->get();

        return response()->json([
            'code' => $stock->code,
            'name' => $stock->name,
            'series' => $series,
            'total' => array_sum($series),
            'status' => $topics->contains('status', 'terverifikasi') ? 'terverifikasi' : 'belum_ada_sumber',
            'topics' => $topics->map(fn ($t) => [
                'id' => $t->id,
                'title' => $t->title,
                'report_count' => $t->reports_count,
                'source_count' => (int) $t->source_count,
                'status' => $t->status,
                'last_report_at' => $t->last_report_at,
            ])->values(),
        ]);
    }
}
