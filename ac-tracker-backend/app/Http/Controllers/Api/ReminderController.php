<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reminder;
use Illuminate\Http\Request;

class ReminderController extends Controller
{
    public function index(Request $request)
    {
        $query = Reminder::query()->orderBy('remind_at');

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'description' => 'required|string|max:500',
            'location' => 'nullable|string|max:255',
            'remind_at' => 'required|date',
        ]);

        $reminder = Reminder::create([...$validated, 'status' => 'pending']);

        return response()->json($reminder, 201);
    }

    public function show(Reminder $reminder)
    {
        return response()->json($reminder);
    }

    public function update(Request $request, Reminder $reminder)
    {
        $validated = $request->validate([
            'description' => 'sometimes|required|string|max:500',
            'location' => 'nullable|string|max:255',
            'remind_at' => 'sometimes|required|date',
        ]);

        $reminder->update($validated);

        return response()->json($reminder);
    }

    public function destroy(Reminder $reminder)
    {
        $reminder->delete();

        return response()->json(null, 204);
    }

    /**
     * Mark a reminder as completed, attach an optional follow-up note/photo,
     * and — if a next meeting date is given — automatically create the next reminder.
     */
    public function followUp(Request $request, Reminder $reminder)
    {
        $validated = $request->validate([
            'follow_up_note' => 'nullable|string|max:2000',
            'follow_up_photo' => 'nullable|image|max:5120',
            'next_reminder_at' => 'nullable|date',
            'next_reminder_description' => 'required_with:next_reminder_at|string|max:500',
        ]);

        $photoPath = null;
        if ($request->hasFile('follow_up_photo')) {
            $photoPath = $request->file('follow_up_photo')->store('follow_ups', 'public');
        }

        $nextReminder = null;
        if (!empty($validated['next_reminder_at'])) {
            $nextReminder = Reminder::create([
                'description' => $validated['next_reminder_description'],
                'remind_at' => $validated['next_reminder_at'],
                'status' => 'pending',
            ]);
        }

        $reminder->update([
            'status' => 'completed',
            'follow_up_note' => $validated['follow_up_note'] ?? null,
            'follow_up_photo_path' => $photoPath,
            'next_reminder_id' => $nextReminder?->id,
        ]);

        return response()->json($reminder->fresh());
    }
}
