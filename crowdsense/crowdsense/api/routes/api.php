<?php

use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\StockController;
use App\Http\Controllers\Api\TopicController;
use Illuminate\Support\Facades\Route;

Route::post('devices', [DeviceController::class, 'store'])->middleware('throttle:10,1');

Route::middleware(['auth:sanctum', 'throttle:120,1'])->group(function () {
    Route::get('dashboard', [DashboardController::class, 'index']);
    Route::get('stocks', [StockController::class, 'index']);
    Route::get('stocks/{code}', [StockController::class, 'show']);
    Route::get('topics/{id}', [TopicController::class, 'show']);
    Route::post('reports', [ReportController::class, 'store'])->middleware('throttle:30,1');
});

// Admin (header X-Admin-Key = CROWDSENSE_ADMIN_KEY)
Route::post('topics/{topic}/sources', [TopicController::class, 'addSource']);
Route::patch('topics/{topic}/status', [TopicController::class, 'setStatus']);
