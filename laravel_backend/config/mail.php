<?php

return [
    'default' => env('MAIL_MAILER', 'resend'),
    'mailers' => [
        'resend' => [
            'transport' => 'resend',
            'api_key' => env('RESEND_API_KEY'),
        ],
    ],
    'from' => [
        'address' => env('MAIL_FROM_ADDRESS', 'noreply@lending-pis.com'),
        'name' => env('MAIL_FROM_NAME', 'Lending PIS'),
    ],
];
