@extends('layouts.app')

@section('content')
<div class="min-h-screen flex items-center justify-center p-6">
    <div class="w-full max-w-[540px]">
        <!-- Header -->
        <div class="flex items-center gap-4 mb-8">
            <a href="{{ route('login') }}" class="w-10 h-10 bg-white rounded-xl border border-[#EEE5DD] flex items-center justify-center text-text-dark hover:bg-gray-50 transition-all">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
            </a>
            <div class="px-2.5 py-1.5 bg-primary/10 rounded-lg">
                <span class="text-primary text-[13px] font-[900]">PIL</span>
            </div>
            <h1 class="text-text-dark text-[16px] font-bold">Create Account</h1>
        </div>

        <form action="{{ route('register') }}" method="POST" class="space-y-6">
            @csrf

            <!-- Step Indicators -->
            <div class="bg-white p-4 rounded-2xl border border-[#EEE5DD] flex items-center gap-3">
                <div class="flex flex-col items-center flex-1">
                    <div class="w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center text-xs font-bold">1</div>
                    <span class="text-[10px] font-bold text-primary mt-1">Details</span>
                </div>
                <div class="h-0.5 bg-primary/20 grow"></div>
                <div class="flex flex-col items-center flex-1">
                    <div class="w-8 h-8 rounded-full bg-gray-100 text-text-muted flex items-center justify-center text-xs font-bold">2</div>
                    <span class="text-[10px] font-bold text-text-muted mt-1">Account</span>
                </div>
            </div>

            <div class="bg-white p-6 rounded-3xl border border-[#EEE5DD] shadow-sm space-y-5">
                <div class="flex items-center gap-3 mb-2">
                    <div class="p-2 bg-primary/10 rounded-lg text-primary">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                    </div>
                    <div>
                        <h2 class="text-text-dark font-bold text-sm">Personal Information</h2>
                        <p class="text-text-muted text-[11px]">Let us know who you are</p>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1.5">
                        <label class="text-[13px] font-semibold text-text-dark">First Name *</label>
                        <input type="text" name="firstname" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all">
                    </div>
                    <div class="space-y-1.5">
                        <label class="text-[13px] font-semibold text-text-dark">Last Name *</label>
                        <input type="text" name="lastname" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all">
                    </div>
                </div>

                <div class="space-y-1.5">
                    <label class="text-[13px] font-semibold text-text-dark">Email Address *</label>
                    <input type="email" name="email" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all">
                </div>

                <div class="space-y-1.5">
                    <label class="text-[13px] font-semibold text-text-dark">Password *</label>
                    <input type="password" name="password" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary transition-all">
                </div>

                <div class="space-y-3 pt-2">
                    <label class="text-[13px] font-semibold text-text-dark">Select Role</label>
                    <div class="grid grid-cols-3 gap-3">
                        @foreach(['admin', 'cashier', 'shareholder'] as $role)
                        <label class="relative group cursor-pointer">
                            <input type="radio" name="role" value="{{ $role }}" {{ $role === 'shareholder' ? 'checked' : '' }} class="peer sr-only">
                            <div class="p-3 bg-gray-50 border border-gray-100 rounded-xl flex flex-col items-center gap-1.5 peer-checked:bg-primary peer-checked:border-primary peer-checked:text-white text-text-dark transition-all">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 opacity-70" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                                </svg>
                                <span class="text-[10px] font-bold uppercase">{{ $role }}</span>
                            </div>
                        </label>
                        @endforeach
                    </div>
                </div>
            </div>

            <button type="submit" class="w-full h-[52px] bg-primary text-white font-bold text-[15px] rounded-[14px] shadow-[0_6px_16px_rgba(255,111,0,0.4)] flex items-center justify-center gap-2 hover:opacity-90 transition-all active:scale-[0.98]">
                Create Account
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                </svg>
            </button>
        </form>
    </div>
</div>
@endsection
