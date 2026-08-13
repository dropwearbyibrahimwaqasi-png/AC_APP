<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reminder extends Model
{
    use HasFactory;

    protected $fillable = [
        'description',
        'location',
        'remind_at',
        'status',
        'follow_up_note',
        'follow_up_photo_path',
        'next_reminder_id',
    ];

    protected $casts = [
        'remind_at' => 'datetime',
    ];

    public function nextReminder()
    {
        return $this->belongsTo(Reminder::class, 'next_reminder_id');
    }
}
