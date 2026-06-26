<?php

use App\Http\Controllers\PlutuPaymentCallbackController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/payment/callback', [PlutuPaymentCallbackController::class, 'handle']);
Route::get('/payments/plutu/test', [PlutuPaymentCallbackController::class, 'sandboxTest']);
