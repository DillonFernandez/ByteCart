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
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('product_name');
            $table->string('brand_name');
            $table->string('product_category');
            $table->text('description');
            $table->text('specification');
            $table->boolean('new_stock')->default(false); // changed from integer to boolean
            $table->float('discount')->default(0)->nullable(false);
            $table->string('image')->nullable(); // <-- add this line
            $table->timestamps();
        });

        Schema::create('product_models', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained('products')->onDelete('cascade');
            $table->string('model_name');
            $table->float('price');
            $table->integer('stock');
            $table->string('colors');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('product_models');
        Schema::dropIfExists('products');
    }
};
