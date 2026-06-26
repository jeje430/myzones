<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Booking Receipt {{ $booking_number }}</title>
    <style>
        * { box-sizing: border-box; }

        html, body {
            direction: ltr;
            font-family: DejaVu Sans, sans-serif;
            color: #1f2937;
            font-size: 12px;
            line-height: 1.6;
            margin: 0;
            padding: 24px;
            text-align: left;
        }

        .header {
            text-align: center;
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 2px solid #6B5478;
        }
        .brand {
            font-size: 22px;
            font-weight: bold;
            color: #6B5478;
            margin-bottom: 4px;
        }
        .title {
            font-size: 16px;
            font-weight: bold;
            color: #111827;
        }
        .meta {
            margin-top: 6px;
            color: #6b7280;
            font-size: 11px;
        }
        .section {
            margin-bottom: 18px;
        }
        .section-title {
            font-size: 13px;
            font-weight: bold;
            color: #6B5478;
            margin-bottom: 10px;
            padding-bottom: 4px;
            border-bottom: 1px solid #e5e7eb;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        td {
            padding: 8px 6px;
            vertical-align: top;
            border-bottom: 1px solid #f3f4f6;
        }
        td.label {
            width: 38%;
            color: #6b7280;
            font-weight: bold;
        }
        td.value {
            color: #111827;
            font-weight: bold;
            text-align: right;
        }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 999px;
            background: #f3f4f6;
            color: #374151;
            font-size: 11px;
            font-weight: bold;
        }
        .amount-box {
            margin-top: 8px;
            padding: 12px;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            background: #fafafa;
        }
        .amount-row {
            display: block;
            margin-bottom: 6px;
        }
        .highlight {
            color: #6B5478;
            font-size: 15px;
            font-weight: bold;
        }
        .free {
            color: #059669;
            font-size: 16px;
            font-weight: bold;
        }
        .footer {
            margin-top: 28px;
            padding-top: 12px;
            border-top: 1px dashed #d1d5db;
            text-align: center;
            color: #9ca3af;
            font-size: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="brand">ZONES</div>
        <div class="title">Booking Receipt</div>
        <div class="meta">Receipt No: {{ $booking_number }} | Issued: {{ $generated_at }}</div>
    </div>

    <div class="section">
        <div class="section-title">Booking Details</div>
        <table>
            <tr>
                <td class="label">Hall Name</td>
                <td class="value">{{ $station_name }}</td>
            </tr>
            <tr>
                <td class="label">Booking Number</td>
                <td class="value">{{ $booking_number }}</td>
            </tr>
            <tr>
                <td class="label">Customer Name</td>
                <td class="value">{{ $customer_name }}</td>
            </tr>
            <tr>
                <td class="label">Booking Date</td>
                <td class="value">{{ $booking_date }}</td>
            </tr>
            <tr>
                <td class="label">Time</td>
                <td class="value">{{ $start_time }} — {{ $end_time }}</td>
            </tr>
            <tr>
                <td class="label">Package</td>
                <td class="value">{{ $package_name }}</td>
            </tr>
            <tr>
                <td class="label">Device</td>
                <td class="value">{{ $device_code }}</td>
            </tr>
            <tr>
                <td class="label">Booking Type</td>
                <td class="value"><span class="badge">{{ $booking_type_label }}</span></td>
            </tr>
            <tr>
                <td class="label">Payment Method</td>
                <td class="value">{{ $payment_method_label }}</td>
            </tr>
        </table>
    </div>

    @if(!empty($show_single_amount))
        <div class="section">
            <div class="section-title">Amount</div>
            <div class="amount-box">
                <span class="highlight">{{ $amount }}</span>
            </div>
        </div>
    @endif

    @if(!empty($show_discount_section))
        <div class="section">
            <div class="section-title">Offer Details</div>
            <div class="amount-box">
                <div class="amount-row">Amount before discount: <strong>{{ $amount_before_discount }}</strong></div>
                <div class="amount-row">Discount: <strong>{{ $discount_percent }}%</strong></div>
                <div class="amount-row">Amount after discount: <span class="highlight">{{ $amount_after_discount }}</span></div>
            </div>
        </div>
    @endif

    @if(!empty($show_loyalty_section))
        <div class="section">
            <div class="section-title">Loyalty Reward</div>
            <div class="amount-box">
                <div class="amount-row">Amount: <span class="free">{{ $amount_label ?? 'Free' }}</span></div>
                @if(!empty($loyalty_redemption_note))
                    <div class="amount-row">{{ $loyalty_redemption_note }}</div>
                @endif
                <div class="amount-row">{{ $loyalty_coupon_label }}: <strong>{{ $loyalty_coupon_code ?: '—' }}</strong></div>
                <div class="amount-row">Points per session: <strong>{{ $loyalty_points_per_session }}</strong></div>
                <div class="amount-row">Points redeemed: <strong>{{ $loyalty_points_total }}</strong></div>
                @if(!empty($estimated_sessions_required))
                    <div class="amount-row">Estimated sessions required: <strong>{{ $estimated_sessions_required }}</strong></div>
                @endif
            </div>
        </div>
    @endif

    <div class="footer">
        Thank you for using ZONES — please present this receipt upon arrival.
    </div>
</body>
</html>
