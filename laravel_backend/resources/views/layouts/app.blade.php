<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'PIL - Point of Sale and Lending System') }}</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#FF6F00',
                        secondary: '#FFA726',
                        surface: '#F7F7F7',
                        'text-dark': '#212121',
                        'text-muted': '#757575',
                        error: '#E53935',
                        success: '#4CAF50',
                    },
                    fontFamily: {
                        sans: ['Plus Jakarta Sans', 'sans-serif'],
                    },
                }
            }
        }
    </script>
    <style>
        body {
            background-color: #FFF8F3;
            font-family: 'Plus Jakarta Sans', sans-serif;
        }
        .bg-blob {
            position: fixed;
            border-radius: 50%;
            z-index: -1;
        }
    </style>
</head>
<body class="antialiased">
    <!-- Decorative background blobs -->
    <div class="bg-blob bg-primary/10 w-[220px] h-[220px] -top-[60px] -right-[60px]"></div>
    <div class="bg-blob bg-primary/5 w-[260px] h-[260px] -bottom-[80px] -left-[40px]"></div>

    <main>
        @yield('content')
    </main>

    <!-- Scripts -->
    @stack('scripts')
</body>
</html>
