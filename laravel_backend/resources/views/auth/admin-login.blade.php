@extends('layouts.app')

@section('title', 'Admin Login')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[440px] space-y-8">
        <div class="text-center">
            <div class="inline-flex p-4 bg-primary/10 rounded-3xl text-primary mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m0 0v2m0-2h2m-2 0H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            </div>
            <h1 class="text-2xl font-[900] text-text-dark">Lending PIS</h1>
            <p class="text-text-muted text-sm mt-2">Welcome back! Please enter your details.</p>
        </div>

        <div class="bg-white p-8 rounded-[32px] border border-[#EEE5DD] shadow-sm">
            <form action="{{ route('login') }}" method="POST" class="space-y-6">
                @csrf
                <div class="space-y-2">
                    <label class="text-[13px] font-semibold text-text-dark ml-1">Email Address</label>
                    <input type="email" name="email" value="{{ old('email') }}" required autofocus
                        class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all"
                        placeholder="admin@example.com">
                    @error('email')
                        <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p>
                    @enderror
                </div>

                <div class="space-y-2">
                    <div class="flex justify-between items-center px-1">
                        <label class="text-[13px] font-semibold text-text-dark">Password</label>
                        <a href="{{ route('password.request') }}" class="text-primary text-[11px] font-bold hover:underline">Forgot?</a>
                    </div>
                    <input type="password" name="password" required
                        class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all"
                        placeholder="••••••••">
                    @error('password')
                        <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p>
                    @enderror
                </div>

                <div class="flex items-center gap-2 px-1">
                    <input type="checkbox" name="remember" id="remember" class="rounded text-primary focus:ring-primary border-gray-300">
                    <label for="remember" class="text-xs text-text-muted font-medium">Remember me for 30 days</label>
                </div>

                <button type="submit" class="w-full h-[56px] bg-primary text-white font-bold text-[15px] rounded-[18px] shadow-lg hover:opacity-90 transition-all">
                    Sign In to Dashboard
                </button>
            </form>
        </div>

        <p class="text-center text-text-muted text-xs">
            System version 2.4.0 • Secured by SSL
        </p>
    </div>
</div>
@endsection
