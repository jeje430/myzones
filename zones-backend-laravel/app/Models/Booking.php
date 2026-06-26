<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Booking extends Model
{
    protected $fillable = [
        'user_id',
        'station_id',
        'device_id',
        'package_id',
        'offer_id',
        'booking_number',
        'booking_type',
        'visitor_name',
        'visitor_phone',
        'visitor_email',
        'start_date',
        'end_date',
        'start_time',
        'end_time',
        'hours_count',
        'original_hourly_price',
        'discounted_hourly_price',
        'discount_amount',
        'discount_percent',
        'loyalty_coupon_label',
        'loyalty_coupon_code',
        'loyalty_points_per_session',
        'loyalty_points_total',
        'loyalty_points_awarded_at',
        'loyalty_points_redeemed',
        'subtotal_price',
        'platform_commission_amount',
        'platform_commission_rate',
        'total_price',
        'payment_method',
        'payment_status',
        'booking_status',
        'needs_refund_review',
        'cancelled_at',
        'session_status',
        'is_checked_in',
        'checked_in_at',
        'session_started_at',
        'session_ended_at',
        'session_duration_seconds',
        'receipt_pdf_path',
        'ticket_pdf_path',
        'receipt_image_path',
        'qr_code',
        'booking_source',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'is_checked_in' => 'boolean',
            'needs_refund_review' => 'boolean',
            'cancelled_at' => 'datetime',
            'checked_in_at' => 'datetime',
            'session_started_at' => 'datetime',
            'session_ended_at' => 'datetime',
            'loyalty_points_awarded_at' => 'datetime',
            'session_duration_seconds' => 'integer',
            'original_hourly_price' => 'decimal:2',
            'discounted_hourly_price' => 'decimal:2',
            'discount_amount' => 'decimal:2',
            'subtotal_price' => 'decimal:2',
            'platform_commission_amount' => 'decimal:2',
            'platform_commission_rate' => 'decimal:2',
            'total_price' => 'decimal:2',
        ];
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
