<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hall_join_requests', function (Blueprint $table) {
            $table->id();
            $table->string('hall_name');
            $table->string('address');
            $table->string('city')->nullable();
            $table->string('map_link')->nullable();
            $table->string('manager_email');
            $table->string('manager_name');
            $table->string('commercial_phone');
            $table->json('images')->nullable();
            $table->enum('status', ['pending', 'accepted', 'rejected'])->default('pending');
            $table->decimal('commission_rate', 5, 2)->nullable();
            $table->text('admin_notes')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->foreignId('station_id')->nullable()->constrained('stations')->nullOnDelete();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hall_join_requests');
    }
};
