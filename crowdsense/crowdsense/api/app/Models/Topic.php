<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Topic extends Model
{
    protected $guarded = [];

    protected $casts = ['tickers' => 'array', 'last_report_at' => 'datetime'];

    public function reports()
    {
        return $this->hasMany(Report::class);
    }

    public function sources()
    {
        return $this->hasMany(VerificationSource::class);
    }
}
