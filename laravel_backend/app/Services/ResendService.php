<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ResendService
{
    protected $apiKey;
    protected $baseUrl = 'https://api.resend.com';

    public function __construct()
    {
        $this->apiKey = env('RESEND_API_KEY');
    }

    /**
     * Send an email using Resend API
     */
    public function sendEmail($to, $subject, $html, $from = null, $attachments = [])
    {
        if (!$this->apiKey || str_contains($this->apiKey, 'xxxx')) {
            Log::error('Resend API Key is missing or invalid in .env');
            return false;
        }

        $from = $from ?? config('mail.from.name') . ' <' . config('mail.from.address') . '>';
        
        $payload = [
            'from' => $from,
            'to' => is_array($to) ? $to : [$to],
            'subject' => $subject,
            'html' => $html,
        ];

        if (!empty($attachments)) {
            $payload['attachments'] = $attachments;
        }

        try {
            $response = Http::withToken($this->apiKey)
                ->post("{$this->baseUrl}/emails", $payload);

            if ($response->successful()) {
                Log::info("Email sent via Resend to: " . (is_array($to) ? implode(',', $to) : $to));
                return true;
            }

            Log::error('Resend API Error: ' . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error('Resend Service Exception: ' . $e->getMessage());
            return false;
        }
    }
}
