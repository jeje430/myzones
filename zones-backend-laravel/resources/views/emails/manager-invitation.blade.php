<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>تم قبول طلب انضمام صالتك</title>
</head>
<body style="font-family: Tahoma, Arial, sans-serif; background:#0a0a0a; color:#fff; padding:24px;">
    <div style="max-width:520px;margin:0 auto;background:#161615;border-radius:12px;padding:32px;border:1px solid #333;">
        <h2 style="color:#a855f7;margin-top:0;">Zones</h2>
        <p>مرحباً <strong>{{ $managerName }}</strong>،</p>
        <p>لقد تم قبولك في الانضمام إلى منصة <strong>Zones</strong>.</p>
        <p>تمت الموافقة على طلب انضمام صالتكم <strong>{{ $hallName }}</strong>.</p>
        <p>اضغط على الرابط التالي لاستكمال تسجيل حساب المدير:</p>
        <p style="text-align:center;margin:28px 0;">
            <a href="{{ $registrationUrl }}" style="display:inline-block;background:#6B5478;color:#fff;padding:14px 28px;border-radius:10px;text-decoration:none;font-weight:bold;">
                إكمال التسجيل
            </a>
        </p>
        <p style="color:#999;font-size:13px;word-break:break-all;direction:ltr;text-align:left;">{{ $registrationUrl }}</p>
        <p style="color:#999;font-size:14px;">الرابط صالح لمدة 24 ساعة.</p>
    </div>
</body>
</html>
