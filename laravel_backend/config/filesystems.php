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
                'authorization_token' =>'sl.u.AGpsT8lsiOhgjcJw0JsEp34HTQddlfL-V4-ieRdBQxNVuCRSOVl2v-nWEANn3jjSbVpkdXtUbpdHMEGF-7K1xEiOrU9xBgF2KDfikri6D878UocY77k47srA9dfmammb_jxXP4olde5Ib4Wvf5aiYwY7Jf6GqGS_P_HWN3PcqjYBcAALRejzwaZmtwXkHdR1qCZZ-fW_vYPv_MVKoESagA63Ubb_esZcwBA7lW8lOdA94V8umPEQozBGgA3fNj9oZ-rYSpM2bbGwf3AcCgxADYzrMLzHPUNACKMY_asqXtWLrXEGg_UWVMbTyuHmpPVS9AFHoK_Ia4KT-OHOl3o2JoNrlC2PiTcmUbKtBdjANz13bGlwZrWWAtoKJhnCZSUYbb_Jquxh-r_dCTEoLeWVyGDpkylG4DLtJGnirtG9sZyKfkr8iaFCzU_LKb1vhP-gVa4XaH1h3q1yNde28dpQgLRIZd8dPuO9ef3taV-X0QuZmiQg3b7bexIS6zLihuc0KprDwlRgDYVU4b8EzJydxBelCXAoVw4Sk3MkAqxD5QveMzAESh4qVYTyV5fFhHkuOFsRCTC_fHgQ3qine1Ptm35cNxiHbNoNLnd_WzjeSBOZInm4-umevX2B-RXrSH1vWN4NZEmuXD06jAJhbPB1Sq3YFaVSxXfRIfJAriEmGsO9SDyc_esgYyZry14o3maIN4ylA1FXdxDFJO2l34h-yP27NV9C2E1kaaa12t_HRznCMQYBzi2ZNGZT9iAkVZNCmjC2c0pU4-GWObQzSe8LCazqNaBVKrrAtdPoBWJ-mjMQVWLarNwRVzg9txWgMsv1YRIhtuGbo6i6D12vS95iF6_uB7U3K0E6AWSAeaSSs92hW-va7ExBja-7Q4TvY8433538s45vDrIDigZ4XzvFtg7cCDRcIH4b54UULx80lmLVg_ntVs_vBANlbp61Y23HMNORllf5AyA1atSxidJEugEYkEiuXzS91UwbptSV4gzTIFO1HoBugHYpoBVW2VoPb4Lx5J644fXmYnIVBsxzgqNuxpmZtbyug3IPBUpAT3o8NWVcTJFswS_9gzlAJ5ul7aPtucr_tH-LlIQJeeRLyjSHvpdJSnze-oVI8tAW_OyqSHMNcWNfzvZ0p2sbYvgoOeeATpuBgY27QSsYgUkvLzyx9QWXkg3MWQe-w-03u1rIw75yeTzA6Fi0s-XbaySu8wqg_3KCyEfAmLJ3gY166DxRyKo9dpAXjW2AVVPgTMm1LCS1raQFz6DtQxksu2pPfebjKpkF1nsiMRRYcZwYCCPae8iz8wZaQvznHa_BhvjznPYA0-sgSaMIgPO9KamQydDQRaMfx4Mf-eIOhHHEXXXvd3ZrVzBq7yPYSHB5Ust9ZkPX75Q90W01gAJoRnl9JSmyFPgqY0KG5urpcqKezbRt63N4WzuxRFWvS7eyIh0Zv2nCxc53NqQSpVwnItei7hAPu4X_J_3nnqeQIQeg32gM',
                'root' => 'lending-system',
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
