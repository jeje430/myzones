@echo off
chcp 65001 >nul
title ZONES — نشر الويب على XAMPP (مرة واحدة)
echo.
echo  ============================================
echo   نشر لوحة ZONES على Apache — مرة واحدة
echo   بعدها: XAMPP فقط + المتصفح
echo  ============================================
echo.

set "WEB=C:\xampp\htdocs\zones"
set "REACT=%~dp0zones_react"

where node >nul 2>&1
if errorlevel 1 (
  echo [خطأ] Node.js غير مثبت.
  pause
  exit /b 1
)

cd /d "%REACT%"
echo [1/3] بناء الويب...
call npm run build -- --base /zones/
if errorlevel 1 (
  echo [خطأ] فشل البناء.
  pause
  exit /b 1
)

echo [2/3] نسخ الملفات إلى %WEB% ...
if not exist "%WEB%" mkdir "%WEB%"
xcopy /E /Y /I "%REACT%\dist\*" "%WEB%\" >nul

echo [3/3] تم.
echo.
echo  ============================================
echo   جاهز — افتح من المتصفح:
echo  ============================================
echo   أدمن عام:  http://localhost/zones/super-admin/login
echo   مدير صالة: http://localhost/zones/manager/login
echo   موظف:      http://localhost/zones/employee/login
echo.
echo   API (للاختبار): http://localhost/zones-api/api/lounges
echo.
echo   يومياً: شغّل XAMPP فقط (Apache + MySQL) — بدون تيرمنال.
echo  ============================================
echo.
start "" "http://localhost/zones/manager/login"
pause
