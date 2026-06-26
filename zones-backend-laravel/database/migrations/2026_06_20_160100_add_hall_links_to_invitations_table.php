<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            $table->foreignId('hall_join_request_id')
                ->nullable()
                ->after('invited_by')
                ->constrained('hall_join_requests')
                ->nullOnDelete();

            $table->foreignId('station_id')
                ->nullable()
                ->after('hall_join_request_id')
                ->constrained('stations')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            $table->dropConstrainedForeignId('station_id');
            $table->dropConstrainedForeignId('hall_join_request_id');
        });
    }
};
