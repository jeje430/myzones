<?php

/**
 * Removes reservation test data only — keeps halls, packages, devices, users, staff.
 */

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

$receiptsDir = storage_path('app/public/receipts');
if (is_dir($receiptsDir)) {
    File::cleanDirectory($receiptsDir);
    echo "CLEARED: storage/app/public/receipts/\n";
}

DB::statement('SET FOREIGN_KEY_CHECKS=0');

foreach (['payment_transactions', 'bookings'] as $table) {
    try {
        DB::table($table)->truncate();
        echo "TRUNCATED: {$table}\n";
    } catch (Throwable $e) {
        echo "SKIP {$table}: {$e->getMessage()}\n";
    }
}

DB::statement('SET FOREIGN_KEY_CHECKS=1');

echo "DONE — bookings and payment transactions cleared. Receipt PDFs removed.\n";
echo "Refresh Flutter My Reservations and reception dashboard to sync from API.\n";
