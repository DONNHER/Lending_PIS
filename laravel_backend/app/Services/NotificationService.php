<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Create a notification and handle delivery methods
     */
    public static function send($userId, $title, $content, $category = 'system', $type = 'info', $metadata = [])
    {
        $notification = Notification::create([
            'user_id' => $userId,
            'title' => $title,
            'content' => $content,
            'category' => $category,
            'type' => $type,
            'is_unread' => true,
            'metadata' => $metadata,
        ]);

        $user = User::find($userId);
        if (!$user) return $notification;

        // Check user preferences (Mocked for now)
        $preferences = $user->notification_preferences ?? [
            'email' => true,
            'sms' => ($category === 'security' || $category === 'critical'),
        ];

        // Delivery Method Logic
        if ($preferences['email'] && in_array($category, ['warning', 'critical', 'reminder'])) {
            self::sendEmail($user, $title, $content);
        }

        if ($preferences['sms'] && in_array($category, ['critical', 'security'])) {
            self::sendSms($user, $content);
        }

        return $notification;
    }

    protected static function sendEmail($user, $title, $content)
    {
        try {
            // Reusing basic mail logic or Laravel's Mail facade
            Mail::raw($content, function ($message) use ($user, $title) {
                $message->to($user->email)
                    ->subject("[Lending PIS] $title");
            });
        } catch (\Exception $e) {
            Log::error("Failed to send notification email: " . $e->getMessage());
        }
    }

    protected static function sendSms($user, $content)
    {
        $phoneNumber = $user->shareholder->contact_number ?? null;
        if (!$phoneNumber) return;

        // Mock SMS logic
        Log::info("SMS SENT to $phoneNumber: $content");
    }
}
