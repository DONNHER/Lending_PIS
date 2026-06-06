<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('products')) {
            Schema::create('products', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->text('product_name');
                $table->text('barcode')->nullable()->unique();
                $table->text('product_image')->nullable();
                $table->decimal('selling_price', 15, 2);
                $table->boolean('is_active')->default(true);
                $table->timestamp('created_at')->useCurrent();
            });
        }
    }

    public function down(): void {}
};
