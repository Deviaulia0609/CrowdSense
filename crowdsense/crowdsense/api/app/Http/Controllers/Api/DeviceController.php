<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DeviceController extends Controller
{
    /** Registrasi anonim per perangkat: mengembalikan token Sanctum. */
    public function store()
    {
        $user = User::create([
            'name' => 'device',
            'email' => Str::uuid() . '@device.local',
            'password' => Hash::make(Str::random(40)),
        ]);

        return response()->json(['token' => $user->createToken('mobile')->plainTextToken], 201);
    }
}
