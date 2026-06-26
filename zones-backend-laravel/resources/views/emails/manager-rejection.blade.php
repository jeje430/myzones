<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>بخصوص طلب انضمام صالتك</title>
</head>
<body style="font-family: Tahoma, Arial, sans-serif; background:#0a0a0a; color:#fff; padding:24px;">
    <div style="max-width:520px;margin:0 auto;background:#161615;border-radius:12px;padding:32px;border:1px solid #333;">
        <h2 style="color:#a855f7;margin-top:0;">Zones</h2>
        <p>مرحباً <strong>{{ $managerName }}</strong>،</p>
        <p>شكراً على اهتمامك بالانضمام إلى منصة <strong>Zones</strong>.</p>
        <p>بعد مراجعة طلب انضمام صالتكم <strong>{{ $hallName }}</strong>، نأسف لإعلامك بأنه <strong>تم رفض الطلب</strong>.</p>

        @if($reason)
        <div style="background:#1f1f1f;border-right:3px solid #dc2626;border-radius:8px;padding:14px 16px;margin:20px 0;">
            <p style="margin:0;font-size:13px;color:#fca5a5;">سبب الرفض:</p>
            <p style="margin:8px 0 0;color:#fff;">{{ $reason }}</p>
        </div>
        @endif

        <p style="color:#aaa;font-size:14px;">يمكنك تعديل البيانات وإعادة التقديم مستقبلاً.</p>
        <p style="margin-top:24px;color:#666;font-size:13px;">— فريق Zones</p>
    </div>
</body>
</html>
