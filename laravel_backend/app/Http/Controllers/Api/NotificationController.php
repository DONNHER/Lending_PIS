<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ResendService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    protected $resend;

    public function __construct(ResendService $resend)
    {
        $this->resend = $resend;
    }

    /**
     * Trigger a Resend email from the app
     */
    public function sendEmail(Request $request)
    {
        $request->validate([
            'to' => 'required|email',
            'subject' => 'required|string',
            'message' => 'required|string',
        ]);

        $html = "<div style='font-family: sans-serif; line-height: 1.5;'>";
        $html .= "<h2>Notification</h2>";
        $html .= "<p>" . nl2br(e($request->message)) . "</p>";
        $html .= "</div>";

        $success = $this->resend->sendEmail(
            $request->to,
            $request->subject,
            $html
        );

        if ($success) {
            return response()->json(['success' => true, 'message' => 'Email sent via Resend']);
        }

        return response()->json(['success' => false, 'message' => 'Failed to send email'], 500);
    }
}
