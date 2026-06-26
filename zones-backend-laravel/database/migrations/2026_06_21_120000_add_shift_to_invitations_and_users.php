<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            $table->string('shift', 20)->nullable()->after('role');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('work_shift', 20)->nullable()->after('station_id');
        });
    }

    public function down(): void
    {
        Schema::table('invitations', function (Blueprint $table) {
            $table->dropColumn('shift');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('work_shift');
        });
    }
};
