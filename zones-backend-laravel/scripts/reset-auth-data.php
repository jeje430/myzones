<?php

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

DB::statement('SET FOREIGN_KEY_CHECKS=0');

$tables = [
    'personal_access_tokens',
    'password_reset_codes',
    'sessions',
    'invitations',
    'hall_join_requests',
    'model_has_roles',
    'model_has_permissions',
    'stations',
    'users',
];

foreach ($tables as $table) {
    try {
        DB::table($table)->truncate();
        echo "TRUNCATED: {$table}\n";
    } catch (Throwable $e) {
        echo "SKIP {$table}: {$e->getMessage()}\n";
    }
}

DB::statement('SET FOREIGN_KEY_CHECKS=1');

echo "DONE — all users, join requests, and invitations cleared.\n";
