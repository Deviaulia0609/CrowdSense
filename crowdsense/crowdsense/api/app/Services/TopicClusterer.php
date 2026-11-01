<?php

namespace App\Services;

use App\Models\Topic;

/**
 * Menggabungkan laporan yang mirip (SimHash dari mobile) ke satu "informasi".
 * MVP: kandidat diambil dari 24 jam terakhir lalu dibandingkan di PHP.
 */
class TopicClusterer
{
    public const THRESHOLD = 10; // bit berbeda maksimum (dari 64)

    public static function split(string $hex): array
    {
        return [hexdec(substr($hex, 0, 8)), hexdec(substr($hex, 8, 8))];
    }

    public static function hamming(int $hi1, int $lo1, int $hi2, int $lo2): int
    {
        return substr_count(decbin($hi1 ^ $hi2), '1') + substr_count(decbin($lo1 ^ $lo2), '1');
    }

    public function assign(string $text, array $tickers, string $simhashHex): Topic
    {
        [$hi, $lo] = self::split($simhashHex);

        $candidates = Topic::where('last_report_at', '>=', now()->subDay())->get();
        foreach ($candidates as $topic) {
            if (array_intersect($topic->tickers, $tickers)
                && self::hamming($hi, $lo, (int) $topic->fp_hi, (int) $topic->fp_lo) <= self::THRESHOLD) {
                return $topic;
            }
        }

        sort($tickers);

        return Topic::create([
            'title' => mb_substr(trim($text), 0, 120),
            'tickers' => array_values($tickers),
            'fp_hi' => $hi,
            'fp_lo' => $lo,
            'last_report_at' => now(),
        ]);
    }
}
