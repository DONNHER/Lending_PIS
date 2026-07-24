<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default filesystem disk that should be used
    | by the framework. The "local" disk, as well as a variety of cloud
    | based disks are available to your application. Grid away!
    |
    */

    'default' => env('FILESYSTEM_DISK', 'local'),

    /*
    |--------------------------------------------------------------------------
    | Filesystem Disks
    |--------------------------------------------------------------------------
    |
    | Here you may configure as many filesystem "disks" as you wish, and you
    | may even configure multiple disks of the same driver. Defaults have
    | been set up for each driver as an example of the required values.
    |
    | Supported Drivers: "local", "ftp", "sftp", "s3"
    |
    */

    'disks' => [

        'local' => [
            'driver' => 'local',
            'root' => storage_path('app'),
            'throw' => false,
        ],
        'dropbox' => [
                'driver' => 'dropbox',
                'authorization_token' => env('sl.u.AGofpsj5Ya-lLBX8L0oaOh7SM7S0_ZPyWPKvB84i1nmGvYMTcNfueAGxntgxHQHlVndy7R7iDqIQLRb1c830MtzkgHi6icrC0C3sCSsCcjfHdm6CfHCp0bgsZS26zJQHs2crCCZoJ-lKcdnwIwP9Fkojyj_vWVIkwXvnGMeB8Tp2WE8hW4vUZbsBYwEg2snhBD9BL20lgity0P1X_o_-ZDKJVQPgeH_H8Ogh7rQT8NAGKKIF8xGMiO6gYu0-ArBwEU7MBdqmYM-QL8D5H6nEX5uTY2tOTMhTDn1nDKuqouEXVujRU3QALBudIuE8qnbrEQLAs9lA4E6gsk7TYbAISv3ZvchQ5cX3k1evVZKIJdAbIb64zaKDSUMS57IzrmOt4CsDUlNpx1zdGk39anYYX4FX-Y8E9HuvPkZtefSgWqbHKcBw5ynl6f_0dRvGhmRAc1I4ZR-dEFUxQLGFcyLJCYK7hNNbZJMByUziIyfB6k9K51UjZxUqBN82aoUm78XspR26DIvCipN24iHlff8QNkOx-QBNm0LrxwftsYfkJWNdCVx6gBBkCzuKAHH1R74cQJX2-uF5BdrjiPcEor16vdtr2KfIACRN-vjpworBRseummA0VdYtF-GPHSmiErYZ-5j2hCRlDAVzs7KIszNCT6kCly0G_ZVi5Ws1yVYBanSzkCJ0Q-bLcQjaxTkbEX4G4ExxvHgv2fAU1AUfFlOwmTqOEhNJbia8O6c_nfulMhzUAJj5Dpv8GY7fRDr5fDF3jt31-ond45DZqhI_1DXfF3fr3_0RoOxhryk_mBln5LVeudK6FqlCJQOi0FGb3tLABE8K7y480Eyoa2dwWKH_otjCkxNSbj2Cm7L8qxHcR263ojeHDhX-3RliKHbeWE2N8MeJswDK0tRwboYJTTpLwR5tv_KOweO_r5iIGcf5rQ8hcgK3vQ5YkNjwnMpWSb_AX09rPHhMCdG4yMICYQ7PNZDb25w11YVaFe-lUnQibloK2gamW3t1wMf7b2sJBW9iDQ1frkK5iCNwrxmRAruqs2uOss6XyY9wcZ9GHnTuJInm2yNsdYUPSM4hxhYxDA2DBTMj7N1B4u_gVmO7qXrDpmpkLvt36jGlIJ78V1S5UzLnJhfeLlfsKQR2Ui6ZzbqhKOzs9GSgGlfw6rAGXA11Yqp34Nlnoc9cTcfQMjwZSn5EN3KZ2BRyv_Lq9FqBEh3hhTLvLEJ9q8h_yzsRqvsrU_lxPXUWTRD9WdEXz-S5xSZPmVGcAndRMEqH7uj0MfXYcvH-EkJNU45Z5tU9n-E2ISq1N5hl_BUaL6rpOxzoImafpE0d40mVRBK0xfkaE8ei-CXvsMbnrPkW-eFFsOb9LzuBKSliXGkyRmQzSCwKxVGjUTmvVzN7GaiLY-uMJofaElOv122ByUpJPFXxn19JRZsJ3A1iqWHDocEXtca43uOSM9hXEJDoyV-psh-ijh7iWOslciwqectCxAPr5pOqfGuL'),
                'root' => 'Lending System',
            ],

        'public' => [
            'driver' => 'local',
            'root' => storage_path('app/public'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'throw' => false,
        ],

        's3' => [
            'driver' => 's3',
            'key' => env('AWS_ACCESS_KEY_ID'),
            'secret' => env('AWS_SECRET_ACCESS_KEY'),
            'region' => env('AWS_DEFAULT_REGION'),
            'bucket' => env('AWS_BUCKET'),
            'url' => env('AWS_URL'),
            'endpoint' => env('AWS_ENDPOINT'),
            'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
            'throw' => true,
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Symbolic Links
    |--------------------------------------------------------------------------
    |
    | Here you may configure the symbolic links that will be created the
    | `storage:link` Artisan command is executed. The array keys should be
    | the locations of the links and the values should be their targets.
    |
    */

    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],

];
