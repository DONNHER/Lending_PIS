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
        Schema::create('import_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('filename');
            $table->string('module'); // e.g., books, users, shareholders
            $table->integer('total_rows')->default(0);
            $table->integer('processed_rows')->default(0);
            $table->integer('failed_rows')->default(0);
            $table->json('errors')->nullable();
            $table->string('status')->default('pending'); // pending, processing, completed, failed
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users');
        });

        Schema::create('export_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('filename');
            $table->string('format'); // xlsx, csv, pdf
            $table->json('filters')->nullable();
            $table->string('download_url')->nullable();
            $table->string('status')->default('pending'); // pending, processing, completed, failed
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('export_logs');
        Schema::dropIfExists('import_logs');
    }
};
