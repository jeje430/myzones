<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Invitation extends Model
{
    use HasFactory;

    protected $fillable = [

        'name',
        'station_name',
        'email',
        'role',
        'token',
        'invited_by',
        'expires_at',
        'used_at',

    ];

    protected $casts = [

        'expires_at' => 'datetime',
        'used_at' => 'datetime',

    ];
}
