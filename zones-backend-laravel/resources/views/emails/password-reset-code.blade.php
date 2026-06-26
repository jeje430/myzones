<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>رمز استعادة كلمة المرور</title>
</head>
<body style="font-family: Tahoma, Arial, sans-serif; background:#0a0a0a; color:#fff; padding:24px;">
    <div style="max-width:480px;margin:0 auto;background:#161615;border-radius:12px;padding:32px;border:1px solid #333;">
        <h2 style="color:#a855f7;margin-top:0;">Zones</h2>
        <p>مرحباً {{ $userName }}،</p>
        <p>تلقّينا طلباً لاستعادة كلمة المرور لحسابك. استخدم الرمز التالي:</p>
        <p style="font-size:32px;font-weight:bold;letter-spacing:8px;text-align:center;color:#22d3ee;margin:24px 0;">
            {{ $code }}
        </p>
        <p style="color:#999;font-size:14px;">صلاحية الرمز: 15 دقيقة. إذا لم تطلب هذا، تجاهل الرسالة.</p>
    </div>
</body>
</html>
