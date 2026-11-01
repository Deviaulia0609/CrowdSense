<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/** Menghitung jumlah laporan per 2 menit selama 10 menit terakhir (5 bucket, lama -> baru). */
class ActivityService
{
    public function series(?array $codes = null): array
    {
        $now = now()->timestamp;
        $rows = DB::table('report_stock')
            ->join('reports', 'reports.id', '=', 'report_stock.report_id')
            ->where('reports.created_at', '>=', now()->subMinutes(10))
            ->when($codes, fn ($q) => $q->whereIn('report_stock.stock_code', $codes))
            ->get(['report_stock.stock_code', 'reports.created_at']);

        $out = [];
        foreach ($rows as $row) {
            $age = max(0, $now - strtotime($row->created_at));
            $bucket = min(4, intdiv($age, 120)); // 0 = terbaru
            $out[$row->stock_code] ??= [0, 0, 0, 0, 0];
            $out[$row->stock_code][4 - $bucket]++;
        }

        return $out;
    }
}
