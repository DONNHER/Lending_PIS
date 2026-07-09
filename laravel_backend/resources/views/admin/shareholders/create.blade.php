@extends('layouts.dashboard')

@section('title', 'Add Shareholder')
@section('header_title', 'Register New Shareholder')

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5]">
            <h3 class="text-text-dark font-bold text-lg">Personal Information</h3>
            <p class="text-text-muted text-sm">Enter the details of the new shareholder</p>
        </div>

        <form action="{{ route('register') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">First Name <span class="text-error">*</span></label>
                    <input type="text" name="firstname" value="{{ old('firstname') }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('firstname') ring-1 ring-error @enderror">
                    @error('firstname') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Last Name <span class="text-error">*</span></label>
                    <input type="text" name="lastname" value="{{ old('lastname') }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('lastname') ring-1 ring-error @enderror">
                    @error('lastname') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
                </div>
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Email Address <span class="text-error">*</span></label>
                <input type="email" name="email" value="{{ old('email') }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('email') ring-1 ring-error @enderror">
                @error('email') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @enderror
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Temporary Password <span class="text-error">*</span></label>
                <input type="password" name="password" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('password') ring-1 ring-error @enderror">
                @error('password') <p class="text-[10px] text-error font-bold">{{ $message }}</p> @else <p class="text-[10px] text-text-muted">Minimum 8 characters. The user should change this upon login.</p> @enderror
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Role</label>
                <select name="role" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                    <option value="shareholder">Shareholder (Member)</option>
                    <option value="cashier">Cashier (Staff)</option>
                    <option value="admin">Administrator</option>
                </select>
            </div>

            <div class="pt-4">
                <button type="submit" class="w-full bg-primary text-white font-bold py-4 rounded-xl shadow-lg hover:opacity-90 transition-all">
                    Register Shareholder
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
