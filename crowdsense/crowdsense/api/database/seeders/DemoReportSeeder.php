<?php

namespace Database\Seeders;

use App\Models\Report;
use App\Models\User;
use App\Models\VerificationSource;
use App\Services\TopicClusterer;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/** Data contoh agar dashboard langsung terisi. Jalankan: php artisan db:seed --class=DemoReportSeeder */
class DemoReportSeeder extends Seeder
{
    public function run(TopicClusterer $clusterer): void
    {
        $user = User::create(['name' => 'demo', 'email' => 'demo@device.local', 'password' => Hash::make(Str::random(20))]);

        $plan = [
            ['BBCA', 'Rumor BBCA akan melakukan akuisisi bank kecil, ramai dibahas di grup', [12, 18, 25, 47, 81], 'grup_chat', 'belum_pasti'],
            ['GOTO', 'Pembahasan GOTO naik di forum soal kerja sama baru', [3, 4, 6, 8, 10], 'forum', 'netral'],
            ['TLKM', 'Pengumuman dividen TLKM dibahas di forum', [2, 2, 3, 3, 4], 'forum', 'netral'],
        ];

        foreach ($plan as [$code, $text, $series, $source, $label]) {
            $topic = null;
            foreach ($series as $i => $n) {
                $bucket = 4 - $i; // 0 = terbaru
                for ($k = 0; $k < $n; $k++) {
                    $at = now()->subSeconds($bucket * 120 + random_int(5, 110));
                    $hex = substr(md5($text), 0, 16);
                    $topic = $clusterer->assign($text, [$code], $hex);
                    $report = Report::unguarded(fn () => Report::create([
                        'client_id' => (string) Str::uuid(), 'user_id' => $user->id, 'topic_id' => $topic->id,
                        'text' => $text, 'source_category' => $k % 3 === 0 ? 'medsos' : $source,
                        'language_label' => $label, 'simhash' => $hex, 'created_at' => $at, 'updated_at' => $at,
                    ]));
                    $report->stocks()->sync([$code]);
                }
            }
            $topic?->update(['last_report_at' => now()->subSeconds(30)]);
            if ($code === 'TLKM' && $topic) {
                VerificationSource::create(['topic_id' => $topic->id, 'name' => 'Keterbukaan informasi TLKM', 'published_at' => now()]);
                $topic->update(['status' => 'terverifikasi']);
            }
        }
    }
}
