```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | العلاقات
            |--------------------------------------------------------------------------
            */

            $table->foreignId('user_id')
    ->nullable()
    ->constrained('users')
    ->nullOnDelete();

            $table->foreignId('station_id')
    ->constrained('stations')
    ->cascadeOnDelete();

            $table->foreignId('device_id')
    ->nullable()
    ->constrained('devices')
    ->nullOnDelete();

            $table->foreignId('package_id')
    ->constrained('packages')
    ->cascadeOnDelete();

            $table->foreignId('offer_id')->nullable();

            /*
            |--------------------------------------------------------------------------
            | بيانات الحجز
            |--------------------------------------------------------------------------
            */

            $table->string('booking_number')->unique();

            /*
            |--------------------------------------------------------------------------
            | التاريخ والوقت
            |--------------------------------------------------------------------------
            */

            $table->date('start_date');

            $table->date('end_date');

            $table->time('start_time');

            $table->time('end_time');

            $table->integer('hours_count');

            /*
            |--------------------------------------------------------------------------
            | الأسعار
            |--------------------------------------------------------------------------
            */

            $table->decimal('original_hourly_price', 10, 2);

            $table->decimal('discounted_hourly_price', 10, 2)->nullable();

            $table->decimal('discount_amount', 10, 2)->default(0);

            $table->decimal('subtotal_price', 10, 2);

            $table->decimal('platform_commission_amount', 10, 2)->default(0);

            $table->decimal('total_price', 10, 2);

            /*
            |--------------------------------------------------------------------------
            | الدفع
            |--------------------------------------------------------------------------
            */

            $table->enum('payment_method', [
                'cash',
                'online',
                'loyalty_reward',
            ]);

            $table->enum('payment_status', [
                'pending',
                'paid',
                'failed',
                'refunded'
            ])->default('pending');

            /*
            |--------------------------------------------------------------------------
            | حالة الحجز
            |--------------------------------------------------------------------------
            */

            $table->enum('booking_status', [
                'pending',
                'confirmed',
                'cancelled',
                'completed',
                'expired'
            ])->default('pending');

            /*
            |--------------------------------------------------------------------------
            | حالة الجلسة
            |--------------------------------------------------------------------------
            */

            $table->enum('session_status', [
                'waiting',
                'checked_in',
                'playing',
                'finished',
                'no_show'
            ])->default('waiting');

            /*
            |--------------------------------------------------------------------------
            | تسجيل الحضور
            |--------------------------------------------------------------------------
            */

            $table->boolean('is_checked_in')->default(false);

            $table->timestamp('checked_in_at')->nullable();

            /*
            |--------------------------------------------------------------------------
            | ملفات الوصل
            |--------------------------------------------------------------------------
            */

            $table->string('receipt_pdf_path')->nullable();

            $table->string('ticket_pdf_path')->nullable();

            /*
            |--------------------------------------------------------------------------
            | صورة الوصل
            |--------------------------------------------------------------------------
            */

            $table->string('receipt_image_path')->nullable();

            /*
            |--------------------------------------------------------------------------
            | QR Code
            |--------------------------------------------------------------------------
            */

            $table->string('qr_code')->nullable();

            /*
            |--------------------------------------------------------------------------
            | مصدر الحجز
            |--------------------------------------------------------------------------
            */

            $table->enum('booking_source', [
                'mobile_app',
                'dashboard',
                'walk_in',
                'phone_call'
            ]);

            /*
            |--------------------------------------------------------------------------
            | ملاحظات
            |--------------------------------------------------------------------------
            */

            $table->text('notes')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
