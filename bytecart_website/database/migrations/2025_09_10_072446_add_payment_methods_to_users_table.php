<?php
// MySQL (XAMPP) migration; no MongoDB usage.

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
            $table->string('payment_method')->nullable(); // Visa/MasterCard, Koko, Mintpay, COD
            $table->string('card_number')->nullable(); // For Visa/MasterCard only
            $table->string('cardholder_name')->nullable(); // For Visa/MasterCard only
            $table->string('expiry_date')->nullable(); // MM/YY, for Visa/MasterCard only
            $table->string('cvv')->nullable(); // For Visa/MasterCard only
            $table->boolean('save_card')->nullable(); // Save card for later
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('payment_method');
            $table->dropColumn('card_number');
            $table->dropColumn('cardholder_name');
            $table->dropColumn('expiry_date');
            $table->dropColumn('cvv');
            $table->dropColumn('save_card');
        });
    }
};
