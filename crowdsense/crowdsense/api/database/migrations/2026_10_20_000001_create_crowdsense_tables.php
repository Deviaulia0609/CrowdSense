<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('stocks', function (Blueprint $t) {
            $t->string('code', 8)->primary();
            $t->string('name');
            $t->timestamps();
        });

        // "Informasi": kumpulan laporan yang mirip untuk saham yang sama.
        Schema::create('topics', function (Blueprint $t) {
            $t->id();
            $t->string('title', 255);
            $t->json('tickers');
            $t->unsignedBigInteger('fp_hi');
            $t->unsignedBigInteger('fp_lo');
            $t->string('status', 30)->default('belum_ada_sumber'); // terverifikasi | belum_ada_sumber | tidak_ditemukan
            $t->timestamp('last_report_at')->nullable()->index();
            $t->timestamps();
        });

        Schema::create('reports', function (Blueprint $t) {
            $t->id();
            $t->uuid('client_id')->unique(); // idempotensi untuk retry dari mobile
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('topic_id')->constrained()->cascadeOnDelete();
            $t->text('text');
            $t->string('source_category', 20);
            $t->string('language_label', 20)->default('netral');
            $t->char('simhash', 16);
            $t->string('attachment_path')->nullable();
            $t->timestamps();
            $t->index('created_at');
        });

        Schema::create('report_stock', function (Blueprint $t) {
            $t->foreignId('report_id')->constrained()->cascadeOnDelete();
            $t->string('stock_code', 8);
            $t->foreign('stock_code')->references('code')->on('stocks')->cascadeOnDelete();
            $t->primary(['report_id', 'stock_code']);
            $t->index('stock_code');
        });

        Schema::create('verification_sources', function (Blueprint $t) {
            $t->id();
            $t->foreignId('topic_id')->constrained()->cascadeOnDelete();
            $t->string('name');
            $t->string('url')->nullable();
            $t->timestamp('published_at')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('verification_sources');
        Schema::dropIfExists('report_stock');
        Schema::dropIfExists('reports');
        Schema::dropIfExists('topics');
        Schema::dropIfExists('stocks');
    }
};
