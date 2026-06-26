<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\PasswordResetCodeMail;
use App\Models\PasswordResetCode;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Throwable;

class PasswordResetController extends Controller
{
    private function allowedRoles(): array
    {
        return ['customer', 'manager', 'reception', 'maintenance', 'super_admin'];
    }

    private function userCanResetPassword(User $user): bool
    {
        return $user->hasAnyRole($this->allowedRoles());
    }

    public function sendCode(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $email = Str::lower(trim($request->email));

        $user = User::where('email', $email)->first();

        if (! $user || ! $this->userCanResetPassword($user)) {
            return response()->json([
                'message' => 'لا يوجد حساب مسجل بهذا البريد الإلكتروني',
            ], 404);
        }

        if ($user->account_status !== 'active') {
            return response()->json([
                'message' => 'هذا الحساب غير نشط. يرجى التواصل مع الإدارة.',
            ], 403);
        }

        PasswordResetCode::where('email', $email)->delete();

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        PasswordResetCode::create([
            'email' => $email,
            'code' => $code,
            'expires_at' => now()->addMinutes(15),
        ]);

        $mailError = null;

        try {
            Mail::to($email)->send(new PasswordResetCodeMail(
                code: $code,
                userName: $user->full_name,
            ));
        } catch (Throwable $e) {
            $mailError = $e->getMessage();
        }

        if ($mailError) {
            return response()->json([
                'message' => 'تعذر إرسال البريد. تحقق من إعدادات Gmail في الخادم.',
                'mail_error' => $mailError,
            ], 500);
        }

        return response()->json([
            'message' => 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
            'email' => $email,
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:6',
            'password' => 'required|min:6|confirmed',
        ]);

        $email = Str::lower(trim($request->email));
        $code = trim($request->code);

        $resetCode = PasswordResetCode::where('email', $email)
            ->where('code', $code)
            ->latest()
            ->first();

        if (! $resetCode || ! $resetCode->isValid()) {
            return response()->json([
                'message' => 'رمز التحقق غير صحيح أو منتهي الصلاحية',
            ], 422);
        }

        $user = User::where('email', $email)->first();

        if (! $user || ! $this->userCanResetPassword($user)) {
            return response()->json([
                'message' => 'لا يوجد حساب مسجل بهذا البريد الإلكتروني',
            ], 404);
        }

        $user->update([
            'password' => $request->password,
        ]);

        $resetCode->update(['used_at' => now()]);
        PasswordResetCode::where('email', $email)->whereNull('used_at')->delete();
        $user->tokens()->delete();

        return response()->json([
            'message' => 'تم تغيير كلمة المرور بنجاح',
        ]);
    }
}
