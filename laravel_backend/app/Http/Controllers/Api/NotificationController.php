<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class NotificationController extends Controller
{
    public function __construct()
    {
        // ResendService removed
    }

    /**
     * Trigger an email from the app using Supabase SMTP
     */
    public function sendEmail(Request $request)
    {
        $request->validate([
            'to' => 'required|email',
            'subject' => 'required|string',
            'message' => 'required|string',
        ]);

        try {
            $emailTo = $request->to;
            $subject = $request->subject;
            $content = $request->message;

            Mail::send([], [], function ($message) use ($emailTo, $subject, $content) {
                $message->to($emailTo)
                    ->subject($subject)
                    ->html("<div style='font-family: sans-serif; line-height: 1.5;'><h2>Notification</h2><p>" . nl2br(e($content)) . "</p></div>");
            });

            return response()->json(['success' => true, 'message' => 'Email sent successfully']);
        } catch (\Exception $e) {
            Log::error("Notification Email Error: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to send email'], 500);
        }
    }
}
