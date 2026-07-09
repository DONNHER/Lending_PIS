@extends('layouts.app')

@section('title', 'Reset Password')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[440px] space-y-8">
        <div class="text-center">
            <div class="inline-flex p-4 bg-primary rounded-[20px] text-white mb-4 shadow-lg shadow-primary/20">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                </svg>
            </div>
            <h1 class="text-2xl font-black text-text-dark tracking-tight">Recover Access</h1>
            <p class="text-text-muted text-sm mt-1 font-medium">Reset your account password</p>
        </div>

        <div class="bg-white p-8 rounded-[32px] border border-[#EEE5DD] shadow-sm">
            @if (session('status'))
                <div class="mb-6 p-4 bg-success/10 text-success text-xs font-bold rounded-2xl border border-success/20">
                    {{ session('status') }}
                </div>
            @endif

            <form action="{{ route('password.email') }}" method="POST" class="space-y-6">
                @csrf
                <div class="space-y-2">
                    <label class="text-[13px] font-semibold text-text-dark ml-1">Email Address</label>
                    <input type="email" name="email" value="{{ old('email') }}" required autofocus class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all" placeholder="name@example.com">
                    @error('email')
                        <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p>
                    @enderror
                </div>

                <button type="submit" class="w-full h-[56px] bg-primary text-white font-bold text-[15px] rounded-[18px] shadow-lg hover:opacity-90 transition-all">
                    Send Reset Link
                </button>
            </form>
        </div>

        <div class="text-center">
            <a href="{{ route('login') }}" class="text-text-muted text-xs font-bold hover:text-text-dark">Back to Login</a>
        </div>
    </div>
</div>
@endsection
