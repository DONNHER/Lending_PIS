@extends('layouts.app')

@section('title', 'Verify Identity')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[440px] space-y-8">
        <div class="text-center">
            <div class="inline-flex p-4 bg-primary/10 rounded-3xl text-primary mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m0 0v2m0-2h2m-2 0H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            </div>
            <h1 class="text-2xl font-[900] text-text-dark">Two-Factor Authentication</h1>
            <p class="text-text-muted text-sm mt-2">Enter the verification code sent to your email.</p>
        </div>

        <div class="bg-white p-8 rounded-[32px] border border-[#EEE5DD] shadow-sm">
            <form action="{{ route('login.mfa.verify') }}" method="POST" class="space-y-6">
                @csrf
                <div class="space-y-2">
                    <label class="text-[13px] font-semibold text-text-dark ml-1">Verification Code</label>
                    <input type="text" name="code" required autofocus class="w-full bg-[#F7F8FA] border-none rounded-2xl p-5 text-center text-2xl font-black tracking-[1em] focus:ring-1 focus:ring-primary transition-all placeholder:text-gray-300" placeholder="000000">
                    @error('code')
                        <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p>
                    @enderror
                </div>

                <button type="submit" class="w-full h-[56px] bg-primary text-white font-bold text-[15px] rounded-[18px] shadow-lg hover:opacity-90 transition-all">
                    Verify & Sign In
                </button>
            </form>

            <div class="mt-8 pt-6 border-t border-gray-100 text-center">
                <p class="text-xs text-text-muted">Didn't receive a code?</p>
                <form action="{{ route('login.mfa.resend') }}" method="POST" class="mt-2">
                    @csrf
                    <button type="submit" class="text-primary text-xs font-bold hover:underline">Resend Code</button>
                </form>
            </div>
        </div>

        <div class="text-center">
            <a href="{{ route('login') }}" class="text-text-muted text-xs font-bold hover:text-text-dark">Back to Login</a>
        </div>
    </div>
</div>
@endsection
