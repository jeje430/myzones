@echo off
chcp 65001 >nul
title ZONES — تشغيل الويب
echo.
echo  ========================================
echo   ZONES — تشغيل لوحة التحكم (React)
echo  ========================================
echo.
echo  تأكد أن XAMPP شغّال: Apache + MySQL
echo  الـ API يشتغل تلقائياً على: http://localhost/zones-api/api
echo.

cd /d "%~dp0zones_react"

where node >nul 2>&1
if errorlevel 1 (
  echo [خطأ] Node.js غير مثبت. نزّله من https://nodejs.org
  pause
  exit /b 1
)

echo  جاري فتح المتصفح...
start "" "http://localhost:5173"

echo  جاري تشغيل React...
npm run dev
