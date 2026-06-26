<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reviews', function (Blueprint $table) {
            if (Schema::hasColumn('reviews', 'comment')) {
                $table->dropColumn('comment');
            }
        });

        Schema::table('device_ratings', function (Blueprint $table) {
            if (Schema::hasColumn('device_ratings', 'comment')) {
                $table->dropColumn('comment');
            }
        });
    }

    public function down(): void
    {
        Schema::table('reviews', function (Blueprint $table) {
            $table->text('comment')->default('');
        });

        Schema::table('device_ratings', function (Blueprint $table) {
            $table->text('comment')->nullable();
        });
    }
};
