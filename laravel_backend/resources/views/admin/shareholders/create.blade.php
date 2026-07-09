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
                    <label class="text-sm font-bold text-text-dark">First Name</label>
                    <input type="text" name="firstname" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Last Name</label>
                    <input type="text" name="lastname" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                </div>
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Email Address</label>
                <input type="email" name="email" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Temporary Password</label>
                <input type="password" name="password" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                <p class="text-[10px] text-text-muted">Minimum 8 characters. The user should change this upon login.</p>
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
