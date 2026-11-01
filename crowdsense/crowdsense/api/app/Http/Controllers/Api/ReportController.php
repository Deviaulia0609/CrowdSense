<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\Stock;
use App\Services\TopicClusterer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function store(Request $request, TopicClusterer $clusterer)
    {
        $data = $request->validate([
            'client_id' => 'required|uuid',
            'text' => 'required|string|min:5|max:1000',
            'tickers' => 'required|string|max:200',
            'source_category' => 'required|in:medsos,forum,grup_chat,lainnya',
            'language_label' => 'nullable|in:netral,belum_pasti,promosi,tekanan,peringatan',
            'simhash' => ['required', 'regex:/^[0-9a-f]{16}$/'],
            'image' => 'nullable|image|max:3072',
        ]);

        // Idempotent: mobile boleh mengulang kirim (backoff) tanpa membuat duplikat.
        if ($existing = Report::where('client_id', $data['client_id'])->first()) {
            return response()->json(['id' => $existing->id, 'topic_id' => $existing->topic_id], 200);
        }

        $codes = collect(explode(',', $data['tickers']))
            ->map(fn ($c) => strtoupper(trim($c)))->filter()->unique()->values();
        $valid = Stock::whereIn('code', $codes)->pluck('code')->all();
        abort_if(empty($valid), 422, 'Kode saham tidak dikenal.');

        $report = DB::transaction(function () use ($request, $data, $valid, $clusterer) {
            $topic = $clusterer->assign($data['text'], $valid, $data['simhash']);
            $topic->tickers = array_values(array_unique(array_merge($topic->tickers, $valid)));
            $topic->last_report_at = now();
            $topic->save();

            $report = Report::create([
                'client_id' => $data['client_id'],
                'user_id' => $request->user()->id,
                'topic_id' => $topic->id,
                'text' => $data['text'],
                'source_category' => $data['source_category'],
                'language_label' => $data['language_label'] ?? 'netral',
                'simhash' => $data['simhash'],
                'attachment_path' => $request->hasFile('image')
                    ? $request->file('image')->store('evidence', 'public') : null,
            ]);
            $report->stocks()->sync($valid);

            return $report;
        });

        return response()->json(['id' => $report->id, 'topic_id' => $report->topic_id], 201);
    }
}
