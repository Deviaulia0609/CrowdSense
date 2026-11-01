<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Topic;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class TopicController extends Controller
{
    public function show(int $id)
    {
        $t = Topic::with('sources')->findOrFail($id);
        $q = $t->reports();

        $recent = $t->reports()->latest()->limit(20)->get();
        $first = $t->reports()->min('created_at');

        return response()->json([
            'id' => $t->id,
            'title' => $t->title,
            'tickers' => $t->tickers,
            'status' => $t->status,
            'report_count' => $q->count(),
            'user_count' => $q->distinct()->count('user_id'),
            'minutes_span' => $first ? (int) now()->parse($first)->diffInMinutes($t->last_report_at ?? now(), true) : 0,
            'source_categories' => $t->reports()->distinct()->pluck('source_category'),
            'language_counts' => $t->reports()->select('language_label', DB::raw('count(*) as c'))
                ->groupBy('language_label')->pluck('c', 'language_label'),
            'sources' => $t->sources->map(fn ($s) => ['name' => $s->name, 'url' => $s->url, 'published_at' => $s->published_at]),
            'attachments' => $recent->whereNotNull('attachment_path')
                ->map(fn ($r) => Storage::disk('public')->url($r->attachment_path))->values(),
            'reports' => $recent->map(fn ($r) => [
                'text' => $r->text,
                'source_category' => $r->source_category,
                'language_label' => $r->language_label,
                'created_at' => $r->created_at,
            ])->values(),
        ]);
    }

    // ---- Admin: hasil pemeriksaan sumber resmi (manual / dari job eksternal) ----
    private function admin(Request $r): void
    {
        $key = config('crowdsense.admin_key');
        abort_unless($key && hash_equals($key, (string) $r->header('X-Admin-Key')), 403);
    }

    public function addSource(Request $r, Topic $topic)
    {
        $this->admin($r);
        $d = $r->validate([
            'name' => 'required|string|max:150',
            'url' => 'nullable|url',
            'published_at' => 'nullable|date',
        ]);
        $topic->sources()->create($d);
        $topic->update(['status' => 'terverifikasi']);

        return response()->json(['status' => $topic->status], 201);
    }

    public function setStatus(Request $r, Topic $topic)
    {
        $this->admin($r);
        $d = $r->validate(['status' => 'required|in:terverifikasi,belum_ada_sumber,tidak_ditemukan']);
        $topic->update($d);

        return response()->json(['status' => $topic->status]);
    }
}
