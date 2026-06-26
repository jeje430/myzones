<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('device_faults', function (Blueprint $table) {
            $table->id();
            $table->foreignId('station_id')->constrained('stations')->cascadeOnDelete();
            $table->foreignId('device_id')->constrained('devices')->cascadeOnDelete();
            $table->foreignId('reported_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('fault_type', 40);
            $table->string('fault_type_custom', 120)->nullable();
            $table->text('details')->nullable();
            $table->enum('status', ['pending', 'in_progress', 'resolved'])->default('pending');
            $table->decimal('maintenance_cost', 10, 2)->default(0);
            $table->string('maintenance_employee_name')->nullable();
            $table->timestamp('reported_at');
            $table->timestamp('resolved_at')->nullable();
            $table->boolean('archived')->default(false);
            $table->timestamps();

            $table->index(['station_id', 'archived', 'status']);
            $table->index(['device_id', 'archived']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_faults');
    }
};
