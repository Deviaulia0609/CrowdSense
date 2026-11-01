<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VerificationSource extends Model
{
    protected $guarded = [];

    protected $casts = ['published_at' => 'datetime'];

    public function topic()
    {
        return $this->belongsTo(Topic::class);
    }
}
