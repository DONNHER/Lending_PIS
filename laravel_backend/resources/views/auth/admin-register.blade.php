@extends('layouts.app')

@section('title', 'Register New User')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[500px] space-y-8">
        <div class="text-center">
            <div class="inline-flex p-4 bg-primary rounded-[20px] text-white mb-4 shadow-lg shadow-primary/20">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
            </div>
            <h1 class="text-2xl font-black text-text-dark tracking-tight">Create Account</h1>
            <p class="text-text-muted text-sm mt-1 font-medium">Register a new system user</p>
        </div>

        <div class="bg-white p-8 rounded-[32px] border border-[#EEE5DD] shadow-sm">
            <form action="{{ route('register') }}" method="POST" class="space-y-5">
                @csrf

                <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-2">
                        <label class="text-[13px] font-semibold text-text-dark ml-1">First Name</label>
                        <input type="text" name="firstname" value="{{ old('firstname') }}" required
                            class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all" placeholder="John">
                        @error('firstname') <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p> @enderror
                    </div>
                    <div class="space-y-2">
                        <label class="text-[13px] font-semibold text-text-dark ml-1">Last Name</label>
                        <input type="text" name="lastname" value="{{ old('lastname') }}" required
                            class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all" placeholder="Doe">
                        @error('lastname') <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p> @enderror
                    </div>
                </div>

                <div class="space-y-2">
                    <label class="text-[13px] font-semibold text-text-dark ml-1">Email Address</label>
                    <input type="email" name="email" value="{{ old('email') }}" required
                        class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all" placeholder="email@example.com">
                    @error('email') <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p> @enderror
                </div>

                <div class="space-y-2">
                    <label class="text-[13px] font-semibold text-text-dark ml-1">Role</label>
                    <select name="role" required class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all">
                        <option value="member">Shareholder Member</option>
                        <option value="cashier">Staff / Cashier</option>
                        <option value="admin">Administrator</option>
                    </select>
                    @error('role') <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p> @enderror
                </div>

                <div class="space-y-2">
                    <label class="text-[13px] font-semibold text-text-dark ml-1">Password</label>
                    <input type="password" name="password" required
                        class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all" placeholder="••••••••">
                    @error('password') <p class="text-error text-[11px] mt-1 ml-1">{{ $message }}</p> @enderror
                </div>

                <button type="submit" class="w-full h-[56px] bg-primary text-white font-bold text-[15px] rounded-[18px] shadow-lg hover:opacity-90 transition-all mt-4">
                    Register User
                </button>
            </form>
        </div>

        <div class="text-center">
            <a href="{{ route('dashboard') }}" class="text-text-muted text-xs font-bold hover:text-text-dark">Back to Dashboard</a>
        </div>
    </div>
</div>
@endsection
