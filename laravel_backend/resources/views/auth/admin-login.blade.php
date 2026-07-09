@extends('layouts.app')

@section('title', 'Admin Login')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[440px] space-y-8">
        <div class="text-center">
            <div class="inline-flex p-5 bg-primary rounded-[24px] text-white mb-6 shadow-xl shadow-primary/20">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
            </div>
            <h1 class="text-3xl font-black text-text-dark tracking-tight">Lending PIS</h1>
            <p class="text-text-muted text-sm mt-2 font-medium">Management & Information System</p>
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
