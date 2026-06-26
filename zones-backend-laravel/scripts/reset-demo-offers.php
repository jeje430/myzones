<?php

/**
 * Removes legacy demo offers (no station/package link) from the database.
 * Manager-created offers are kept.
 *
 * Usage: php scripts/reset-demo-offers.php
 */

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Offer;
use App\Models\OfferTimeSlot;

$demoIds = Offer::withTrashed()
    ->where(function ($q) {
        $q->whereNull('package_id')->orWhereNull('station_id');
    })
    ->pluck('id');

if ($demoIds->isEmpty()) {
    echo "No demo offers to remove.\n";
    exit(0);
}

OfferTimeSlot::whereIn('offer_id', $demoIds)->delete();
Offer::withTrashed()->whereIn('id', $demoIds)->forceDelete();

echo 'Removed '.$demoIds->count()." demo offer(s).\n";
