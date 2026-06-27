@echo off
chcp 65001 >nul
title ZONES — إعداد API على XAMPP
echo.
echo  ========================================
echo   ZONES — ربط Laravel بـ XAMPP Apache
echo  ========================================
echo.

set "VHOSTS=C:\xampp\apache\conf\extra\httpd-vhosts.conf"
set "MARKER=ZONES Laravel API"

findstr /C:"%MARKER%" "%VHOSTS%" >nul 2>&1
if not errorlevel 1 (
  echo  [OK] إعداد Apache موجود مسبقاً.
  goto :test
)

echo  جاري إضافة إعداد Apache...
>>"%VHOSTS%" echo.
>>"%VHOSTS%" echo # --- %MARKER% (XAMPP) ---
>>"%VHOSTS%" echo Alias /zones-api "C:/Users/DELL/Desktop/team_zones/zones-backend-laravel/public"
>>"%VHOSTS%" echo ^<Directory "C:/Users/DELL/Desktop/team_zones/zones-backend-laravel/public"^>
>>"%VHOSTS%" echo     Options Indexes FollowSymLinks
>>"%VHOSTS%" echo     AllowOverride All
>>"%VHOSTS%" echo     Require all granted
>>"%VHOSTS%" echo ^</Directory^>
echo  [OK] تمت الإضافة.

:test
echo.
echo  ========================================
echo   الخطوات التالية (مرة واحدة):
echo  ========================================
echo  1. افتح XAMPP Control Panel
echo  2. اضغط Stop ثم Start على Apache
echo  3. شغّل START-ZONES.bat لتشغيل الويب
echo.
echo  اختبار API:
echo  http://localhost/zones-api/api/lounges
echo.

cd /d "%~dp0zones-backend-laravel"
if exist "C:\xampp\php\php.exe" (
  "C:\xampp\php\php.exe" artisan storage:link 2>nul
  "C:\xampp\php\php.exe" artisan config:clear 2>nul
)

echo  جاري اختبار API...
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost/zones-api/api/lounges' -TimeoutSec 10; Write-Host ('  [OK] API يرد — HTTP ' + $r.StatusCode) } catch { Write-Host '  [!] API ما يردش — أعد تشغيل Apache من XAMPP' }"

echo.
pause
