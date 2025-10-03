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
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone_number')->nullable();

            // Billing address fields
            $table->string('billing_street_address')->nullable();
            $table->string('billing_apartment_suite')->nullable();
            $table->string('billing_city')->nullable();
            $table->string('billing_district')->nullable();
            $table->string('billing_zip_code')->nullable();

            // Shipping address fields
            $table->string('shipping_street_address')->nullable();
            $table->string('shipping_apartment_suite')->nullable();
            $table->string('shipping_city')->nullable();
            $table->string('shipping_district')->nullable();
            $table->string('shipping_zip_code')->nullable();

            // Billing same as shipping flag
            $table->boolean('is_billing_same_as_shipping')->default(true);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'phone_number',
                'billing_street_address',
                'billing_apartment_suite',
                'billing_city',
                'billing_district',
                'billing_zip_code',
                'shipping_street_address',
                'shipping_apartment_suite',
                'shipping_city',
                'shipping_district',
                'shipping_zip_code',
                'is_billing_same_as_shipping'
            ]);
        });
    }
};
