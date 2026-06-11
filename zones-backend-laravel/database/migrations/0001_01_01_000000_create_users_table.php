<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {

        /*
        |--------------------------------------------------------------------------
        | Users Table
        |--------------------------------------------------------------------------
        */

        Schema::create('users', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | User Basic Information
            |--------------------------------------------------------------------------
            */

            $table->string('full_name');

            $table->string('phone')
                ->nullable()
                ->unique();

            $table->string('profile_image')
                ->nullable();

            $table->string('email')
                ->unique();

            /*
            |--------------------------------------------------------------------------
            | Verification
            |--------------------------------------------------------------------------
            */

            $table->timestamp('email_verified_at')
                ->nullable();

            $table->timestamp('phone_verified_at')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Authentication
            |--------------------------------------------------------------------------
            */

            $table->string('password');

            $table->rememberToken();

            /*
            |--------------------------------------------------------------------------
            | Account Status
            |--------------------------------------------------------------------------
            */

            $table->enum('account_status', [
                'active',
                'inactive',
                'suspended',
                'blocked'
            ])->default('active');

            /*
            |--------------------------------------------------------------------------
            | Activity Tracking
            |--------------------------------------------------------------------------
            */

            $table->timestamp('last_login_at')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Soft Delete
            |--------------------------------------------------------------------------
            */

            $table->softDeletes();

            /*
            |--------------------------------------------------------------------------
            | Timestamps
            |--------------------------------------------------------------------------
            */

            $table->timestamps();
        });

        /*
        |--------------------------------------------------------------------------
        | Password Reset Tokens Table
        |--------------------------------------------------------------------------
        */

        Schema::create('password_reset_tokens', function (Blueprint $table) {

            $table->string('email')
                ->primary();

            $table->string('token');

            $table->timestamp('created_at')
                ->nullable();
        });

        /*
        |--------------------------------------------------------------------------
        | Sessions Table
        |--------------------------------------------------------------------------
        */

        Schema::create('sessions', function (Blueprint $table) {

            $table->string('id')
                ->primary();

            $table->foreignId('user_id')
                ->nullable()
                ->index();

            $table->string('ip_address', 45)
                ->nullable();

            $table->text('user_agent')
                ->nullable();

            $table->longText('payload');

            $table->integer('last_activity')
                ->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {

        Schema::dropIfExists('sessions');

        Schema::dropIfExists('password_reset_tokens');

        Schema::dropIfExists('users');
    }
};
