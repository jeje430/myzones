<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('hall_expenses', function (Blueprint $table) {
            $table->string('category', 40)->nullable()->after('notes');
            $table->foreignId('device_fault_id')->nullable()->after('category')
                ->constrained('device_faults')->nullOnDelete();
            $table->foreignId('created_by')->nullable()->after('device_fault_id')
                ->constrained('users')->nullOnDelete();

            $table->unique('device_fault_id');
        });
    }

    public function down(): void
    {
        Schema::table('hall_expenses', function (Blueprint $table) {
            $table->dropUnique(['device_fault_id']);
            $table->dropConstrainedForeignId('created_by');
            $table->dropConstrainedForeignId('device_fault_id');
            $table->dropColumn('category');
        });
    }
};
