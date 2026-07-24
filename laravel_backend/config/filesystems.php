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
                'authorization_token' => env('sl.u.AGrcmXGycHC6o15voVqXLHFFPXaJETKDRBZHQ2wAfTDe-fBUuCixjBXZzjLA_HAMQKnNO4A7cu2uVf4M-_r8pbdZhdRo-NL9dzuXQyEIduBYdwFIozgncyS01wGPABl3mvk9ZI3okoLemKXneso0EidVF-35Sv_sdPlkhZ0IgeuoUew4q4_D2Se9sCUdF53GYeQi6iz34R_bQka_eowBELUUb1ZRnMXTzEN9n-oBdPLyfzXr_93at2DlTT7J7Y5x4EIs0v6kkJsH8mDssP1U8xH3Ygn-1lb-0Tboaatz10_AR6fq_QNYgVkLZCXrZhecksmTHa9Xt76QOTngasScwyu7Fzn4o2NQnQ1FrkrQdAeRSWd1vn-UkoPr_6T9wMWyjvAHjDBReB4ZII6D0OU-FLGaijJQdXYEB7-CUWj8a9kJpzQezB0uhv6S566MCZbGgT855VU4WscVM4cdHpkWJLEGJgSV-bb5bwKB3KHHFiIQooMXJaim9W0mgSXFSThgvra7lBhEevuSWquEo5lUIitBirMG3lzZT3LEliMx6RfmwRiKEcjxztFbzyKLARs54O9rrwOin_GqB0NfXy7_XOEZFR8jyuGcTqC1IZReUGGf-0j2IXKNpaprizP04kXvqdgzhKsY0cXIZ8OrGpQqrCuNrmeVqj3kU6bTLGMiHmrGGpk0HeKAi1VLYDDgxb40WnDo3Gs6yQ5clD7TTYxTG6qKWxkcP8M9332M7niY9wiqLMUJv7M-9JUwQjOk2wYXzoQ2Q2AIkgqcRzX9zTAgGZjf_4gWXAH3TvqTlw9WxOY0h_dQyuDHXEjaMOdkolTGXAzOCFxOy1uH4yIEknYA1pUAodYM6PNf4Js54ZUlUJtOwH2mK_6QPUNWaXENzQ2fn8w3V2cYM8CYH2GpMAY5ufZh3B8oh-WqNv_0qSkfk5bqFAX593_QWFBYYep15ptG3q1M7aAAY8YEuOyPWMuxIghlTsdKbk1IlNDc_HcPdePl6oELiCliKAS2SarxDLu3yaU2AEesIGXiL10v1pYxY4RCuNKVw4yAgptbrN2533fbkwSkzChQWn_75oo_KY9Wa_AETYJKi0M5otLnasnC-YwSFrZ81Q8alTPH466vEXcGhvf1KS7jUnYEF9akQg-C0u5XBBgbpfUS44_s9PE5CU70JeV3beSpjWa8pHOf_Cm_2cKjJABKi5bfGsM4qJMNMpQN2cJXn7SmsJiJ4UJ_uplP6FdvQ0mWLmC13Tv8iPFsoa2hXOUiPRPweukZFDufZ1dHW4XYRyrmsDwZqUiw2UFybfSKZ4xh0tbhfxCPB7FMgbBgpA7rWhpvA4bufkAOLVIJAy7ssPHyJO81Aye0lwWSdUBtd5FSX9U9rPpDSoFZ61LfcxsVM59fLrIufCOIaOa30mYAi9h6JmHTxsTys1fA7z6GYORqjEaE5-wvmai2TF6daQbxBUybz822FLney3P-cXvSl5QVmGuOm-1U986c'),
                'root' => 'LendingSystem',
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
