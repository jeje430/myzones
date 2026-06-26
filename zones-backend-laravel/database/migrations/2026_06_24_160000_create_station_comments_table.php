<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('station_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('station_id')->constrained('stations')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('parent_id')->nullable()->constrained('station_comments')->cascadeOnDelete();
            $table->text('body');
            $table->timestamp('edited_at')->nullable();
            $table->timestamps();

            $table->index(['station_id', 'parent_id', 'created_at']);
        });

        if (Schema::hasColumn('reviews', 'comment')) {
            $reviews = DB::table('reviews')
                ->whereNotNull('comment')
                ->where('comment', '!=', '')
                ->whereNotNull('user_id')
                ->get(['id', 'station_id', 'user_id', 'comment', 'created_at', 'updated_at']);

            foreach ($reviews as $review) {
                DB::table('station_comments')->insert([
                    'station_id' => $review->station_id,
                    'user_id' => $review->user_id,
                    'parent_id' => null,
                    'body' => $review->comment,
                    'edited_at' => null,
                    'created_at' => $review->created_at,
                    'updated_at' => $review->updated_at,
                ]);
            }
        }

        if (Schema::hasColumn('device_ratings', 'comment')) {
            $ratings = DB::table('device_ratings')
                ->join('packages', 'packages.id', '=', 'device_ratings.package_id')
                ->whereNotNull('device_ratings.comment')
                ->where('device_ratings.comment', '!=', '')
                ->select([
                    'device_ratings.user_id',
                    'packages.station_id',
                    'device_ratings.comment',
                    'device_ratings.created_at',
                    'device_ratings.updated_at',
                ])
                ->get();

            foreach ($ratings as $row) {
                DB::table('station_comments')->insert([
                    'station_id' => $row->station_id,
                    'user_id' => $row->user_id,
                    'parent_id' => null,
                    'body' => $row->comment,
                    'edited_at' => null,
                    'created_at' => $row->created_at,
                    'updated_at' => $row->updated_at,
                ]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('station_comments');
    }
};
