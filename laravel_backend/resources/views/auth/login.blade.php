@extends('layouts.app')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[440px]">
        <!-- Branding -->
        <div class="flex flex-col items-center mb-11">
            <div class="w-[72px] h-[72px] bg-primary rounded-[20px] shadow-[0_8px_20px_rgba(255,111,0,0.35)] flex items-center justify-center mb-3.5">
                <span class="text-white text-[22px] font-[900] tracking-wider">PIL</span>
            </div>
            <h1 class="text-primary text-[22px] font-[900] tracking-wide mb-1">PIL</h1>
            <p class="text-text-muted text-[12px] font-medium tracking-tight">Point of Sale and Lending System</p>
        </div>

        <!-- Greeting -->
        <div class="mb-8">
            <h2 class="text-text-dark text-[26px] font-[800] tracking-tight leading-tight mb-1.5">Welcome back</h2>
            <p class="text-text-muted text-[14px] leading-relaxed">Sign in to access your PIL dashboard</p>
        </div>

        <!-- Form -->
        <form action="{{ route('login') }}" method="POST">
            @csrf

            @if ($errors->any())
                <div class="mb-4 p-4 bg-error text-white rounded-xl flex items-center gap-3 shadow-lg">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    <span class="text-sm">{{ $errors->first() }}</span>
                </div>
            @endif

            <!-- Email -->
            <div class="mb-4.5 group">
                <label class="block text-[13px] font-semibold text-text-dark mb-2">Email Address</label>
                <div class="relative">
                    <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-text-muted group-focus-within:text-primary transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                    </div>
                    <input type="email" name="email" value="{{ old('email') }}" required
                        class="w-full bg-white border border-primary/20 rounded-[12px] py-4 pl-12 pr-4 text-[14px] focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all placeholder:text-text-muted"
                        placeholder="Enter your email">
                </div>
            </div>

            <div class="h-[18px]"></div>

            <!-- Password -->
            <div class="mb-3 group">
                <label class="block text-[13px] font-semibold text-text-dark mb-2">Password</label>
                <div class="relative">
                    <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-text-muted group-focus-within:text-primary transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                    </div>
                    <input type="password" name="password" id="password" required
                        class="w-full bg-white border border-primary/20 rounded-[12px] py-4 pl-12 pr-12 text-[14px] focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all placeholder:text-text-muted"
                        placeholder="Enter your password">
                    <button type="button" onclick="togglePassword()" class="absolute inset-y-0 right-0 pr-4 flex items-center text-text-muted hover:text-primary">
                        <svg id="eye-icon" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                    </button>
                </div>
            </div>

            <!-- Remember Me & Forgot Password -->
            <div class="flex items-center justify-between mb-7">
                <label class="flex items-center gap-2 cursor-pointer group">
                    <div class="relative flex items-center">
                        <input type="checkbox" name="remember" class="peer h-5 w-5 cursor-pointer appearance-none rounded border border-primary/20 bg-white checked:bg-primary checked:border-primary transition-all">
                        <svg class="absolute w-3.5 h-3.5 text-white opacity-0 peer-checked:opacity-100 pointer-events-none left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                    </div>
                    <span class="text-[13px] text-text-dark font-medium">Remember Me</span>
                </label>
                <a href="{{ route('password.request') }}" class="text-[13px] font-bold text-primary hover:opacity-80 transition-opacity">Forgot Password?</a>
            </div>

            <!-- Sign In Button -->
            <button type="submit" class="w-full h-[52px] bg-primary text-white font-bold text-[15px] rounded-[14px] shadow-[0_6px_16px_rgba(255,111,0,0.4)] flex items-center justify-center gap-2 hover:opacity-90 transition-all active:scale-[0.98]">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                </svg>
                Sign In
            </button>
        </form>

        <!-- Divider -->
        <div class="flex items-center gap-3.5 my-7">
            <div class="h-px bg-[#E8DDD5] grow"></div>
            <span class="text-[12px] text-text-muted">New to PIL?</span>
            <div class="h-px bg-[#E8DDD5] grow"></div>
        </div>

        <!-- Register Link -->
        <a href="{{ route('register') }}" class="w-full h-[52px] border border-primary/40 text-primary font-bold text-[14px] rounded-[14px] flex items-center justify-center hover:bg-primary/5 transition-all">
            Create an Account
        </a>
    </div>
</div>

@push('scripts')
<script>
    function togglePassword() {
        const passwordInput = document.getElementById('password');
        const eyeIcon = document.getElementById('eye-icon');

        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            eyeIcon.innerHTML = `
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" />
            `;
        } else {
            passwordInput.type = 'password';
            eyeIcon.innerHTML = `
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            `;
        }
    }
</script>
@endpush
@endsection
