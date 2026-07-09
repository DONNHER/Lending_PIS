@extends('layouts.app')

@section('title', 'Register New User')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[500px] space-y-8">
        <div class="text-center">
            <h1 class="text-2xl font-[900] text-text-dark">Create Account</h1>
            <p class="text-text-muted text-sm mt-2">Register a new system user with specific roles.</p>
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
