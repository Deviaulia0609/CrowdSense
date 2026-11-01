<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Stock extends Model
{
    protected $primaryKey = 'code';
    public $incrementing = false;
    protected $keyType = 'string';
    protected $guarded = [];

    public function reports()
    {
        return $this->belongsToMany(Report::class, 'report_stock', 'stock_code', 'report_id', 'code', 'id');
    }
}
