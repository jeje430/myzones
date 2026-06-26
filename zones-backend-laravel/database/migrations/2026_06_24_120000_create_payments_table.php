<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('amount', 10, 2);
            $table->enum('payment_method', ['electronic', 'pay_on_arrival']);
            $table->string('transaction_ref')->nullable();
            $table->enum('status', ['completed', 'refunded'])->default('completed');
            $table->timestamp('paid_at');
            $table->timestamps();

            $table->unique('booking_id');
            $table->index(['payment_method', 'paid_at']);
        });

        $this->backfillExistingPayments();
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }

    private function backfillExistingPayments(): void
    {
        $now = now();

        $paidTransactions = DB::table('payment_transactions')
            ->where('status', 'paid')
            ->whereNotNull('booking_id')
            ->orderBy('id')
            ->get();

        foreach ($paidTransactions as $transaction) {
            $booking = DB::table('bookings')->where('id', $transaction->booking_id)->first();
            if (! $booking || in_array($booking->booking_type, ['loyalty'], true)) {
                continue;
            }

            DB::table('payments')->insertOrIgnore([
                'booking_id' => $transaction->booking_id,
                'user_id' => $transaction->user_id ?? $booking->user_id,
                'amount' => $transaction->amount,
                'payment_method' => 'electronic',
                'transaction_ref' => $transaction->invoice_no,
                'status' => 'completed',
                'paid_at' => $transaction->paid_at ?? $now,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        $cashBookings = DB::table('bookings')
            ->where('payment_method', 'cash')
            ->where('payment_status', 'paid')
            ->whereNotNull('checked_in_at')
            ->whereNotIn('booking_type', ['loyalty'])
            ->orderBy('id')
            ->get();

        foreach ($cashBookings as $booking) {
            DB::table('payments')->insertOrIgnore([
                'booking_id' => $booking->id,
                'user_id' => $booking->user_id,
                'amount' => $booking->total_price,
                'payment_method' => 'pay_on_arrival',
                'transaction_ref' => $booking->booking_number,
                'status' => 'completed',
                'paid_at' => $booking->checked_in_at,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }
};
