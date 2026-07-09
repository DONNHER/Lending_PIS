@extends('layouts.dashboard')

@section('title', 'My Profile')
@section('header_title', 'Account Settings')

@section('content')
<div class="max-w-4xl mx-auto space-y-8">
    <!-- Profile Info -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-gray-100">
            <h3 class="text-text-dark font-bold text-lg">Personal Details</h3>
            <p class="text-text-muted text-sm">Update your basic account information</p>
        </div>

        <form action="{{ route('profile.update') }}" method="POST" enctype="multipart/form-data" class="p-8 space-y-6">
            @csrf
            @method('PUT')
            <input type="hidden" name="version" value="{{ $user->version }}">
            @if($user->shareholder)
                <input type="hidden" name="shareholder_version" value="{{ $user->shareholder->version }}">
            @endif

            <div class="flex flex-col md:flex-row items-center gap-8 mb-8 pb-8 border-b border-gray-50">
                <div class="relative group">
                    <div class="w-24 h-24 bg-gray-100 rounded-3xl overflow-hidden border-4 border-white shadow-md">
                        @if($user->avatar_url)
                            <img src="{{ $user->avatar_url }}" class="w-full h-full object-cover">
                        @else
                            <div class="w-full h-full flex items-center justify-center text-gray-400">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                            </div>
                        @endif
                    </div>
                    <label class="absolute bottom-0 right-0 w-8 h-8 bg-primary rounded-xl flex items-center justify-center text-white cursor-pointer shadow-lg hover:scale-110 transition-transform">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                        <input type="file" name="avatar" class="hidden" accept="image/*">
                    </label>
                </div>
                <div>
                    <h4 class="text-text-dark font-bold text-sm">Profile Picture</h4>
                    <p class="text-[10px] text-text-muted uppercase font-bold tracking-tighter">Recommended: Square image, max 2MB</p>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">First Name <span class="text-error">*</span></label>
                    <input type="text" name="firstname" value="{{ old('firstname', $user->firstname) }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('firstname') ring-1 ring-error @enderror">
                    @error('firstname') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Last Name <span class="text-error">*</span></label>
                    <input type="text" name="lastname" value="{{ old('lastname', $user->lastname) }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('lastname') ring-1 ring-error @enderror">
                    @error('lastname') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
                </div>
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Email Address</label>
                <input type="email" value="{{ $user->email }}" disabled class="w-full bg-gray-50 border-none rounded-xl p-4 text-sm text-text-muted cursor-not-allowed">
                <p class="text-[10px] text-text-muted">Email address cannot be changed.</p>
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Phone Number</label>
                <input type="text" name="contact_number" value="{{ old('contact_number', $user->shareholder?->contact_number) }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('contact_number') ring-1 ring-error @enderror" placeholder="e.g. 09123456789">
                @error('contact_number') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Home Address</label>
                <textarea name="address" class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary h-24 @error('address') ring-1 ring-error @enderror">{{ old('address', $user->shareholder?->address) }}</textarea>
                @error('address') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
            </div>

            <div class="flex justify-end pt-4">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg hover:opacity-90 transition-all">
                    Save Changes
                </button>
            </div>
        </form>
    </div>

    <!-- Security Settings -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-gray-100">
            <h3 class="text-text-dark font-bold text-lg">Identity & Security</h3>
            <p class="text-text-muted text-sm">Manage your account security and verification</p>
        </div>

        <div class="p-8 space-y-8">
            <div class="flex items-center justify-between p-6 bg-primary/5 rounded-2xl border border-primary/10">
                <div class="flex items-center gap-4">
                    <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m0 0v2m0-2h2m-2 0H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    </div>
                    <div>
                        <h4 class="text-sm font-bold text-text-dark">Two-Factor Authentication</h4>
                        <p class="text-[10px] text-text-muted">A verification code will be sent to your email during login.</p>
                    </div>
                </div>
                <form action="{{ route('profile.mfa.toggle') }}" method="POST">
                    @csrf
                    @method('PATCH')
                    <button type="submit" class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none {{ $user->mfa_enabled ? 'bg-primary' : 'bg-gray-200' }}">
                        <span class="inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out {{ $user->mfa_enabled ? 'translate-x-5' : 'translate-x-0' }}"></span>
                    </button>
                </form>
            </div>

            <div class="h-px bg-gray-50"></div>

            <form action="{{ route('profile.password') }}" method="POST" class="space-y-6">
            @csrf
            @method('PUT')

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Current Password</label>
                <input type="password" name="current_password" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">New Password</label>
                    <input type="password" name="password" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Confirm New Password</label>
                    <input type="password" name="password_confirmation" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                </div>
            </div>

            <div class="flex justify-end pt-4">
                <button type="submit" class="bg-text-dark text-white font-bold px-8 py-3 rounded-xl shadow-lg hover:opacity-90 transition-all">
                    Update Password
                </button>
            </div>
        </form>
    </div>

    <!-- Notification Preferences -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-gray-100">
            <h3 class="text-text-dark font-bold text-lg">Notification Preferences</h3>
            <p class="text-text-muted text-sm">Choose how you want to be notified</p>
        </div>

        <div class="p-8 space-y-6">
            <div class="flex items-center justify-between">
                <div>
                    <h4 class="text-sm font-bold text-text-dark">Email Notifications</h4>
                    <p class="text-[10px] text-text-muted">Receive alerts for transactions, warnings, and reminders.</p>
                </div>
                <div class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none bg-primary">
                    <span class="inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out translate-x-5"></span>
                </div>
            </div>

            <div class="h-px bg-gray-50"></div>

            <div class="flex items-center justify-between">
                <div>
                    <h4 class="text-sm font-bold text-text-dark">SMS Alerts</h4>
                    <p class="text-[10px] text-text-muted">Critical and security alerts sent directly to your phone.</p>
                </div>
                <div class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none bg-gray-200">
                    <span class="inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out translate-x-0"></span>
                </div>
            </div>

            <p class="text-[10px] text-text-muted italic bg-gray-50 p-4 rounded-xl">Note: Some critical security notifications cannot be disabled for account protection.</p>
        </div>
    </div>
</div>
@endsection
