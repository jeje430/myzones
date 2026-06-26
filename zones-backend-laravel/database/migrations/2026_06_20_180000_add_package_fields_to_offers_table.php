<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('offers', function (Blueprint $table) {
            $table->foreignId('package_id')
                ->nullable()
                ->after('station_id')
                ->constrained('packages')
                ->nullOnDelete();
            $table->unsignedTinyInteger('discount_percent')->default(0)->after('discounted_price');
        });
    }

    public function down(): void
    {
        Schema::table('offers', function (Blueprint $table) {
            $table->dropConstrainedForeignId('package_id');
            $table->dropColumn('discount_percent');
        });
    }
};
