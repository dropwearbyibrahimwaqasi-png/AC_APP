<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reminders', function (Blueprint $table) {
            $table->id();
            $table->string('description');
            $table->dateTime('remind_at');
            $table->enum('status', ['pending', 'completed'])->default('pending');
            $table->text('follow_up_note')->nullable();
            $table->string('follow_up_photo_path')->nullable();
            // Self-reference: if a follow-up gives a next meeting date, the
            // auto-created reminder is linked back here.
            $table->foreignId('next_reminder_id')->nullable()->constrained('reminders')->nullOnDelete();
            $table->timestamps();

            $table->index('remind_at');
        });
    }

    public function down(): void
    {
        Schema::table('reminders', function (Blueprint $table) {
            $table->dropForeign(['next_reminder_id']);
        });
        Schema::dropIfExists('reminders');
    }
};
