@extends('layouts.dashboard')

@section('title', 'Shareholder Profile')
@section('header_title', 'Shareholder Profile')

@section('content')
<div class="max-w-6xl mx-auto space-y-8" x-data="{ editModal: false }">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-gray-100 flex flex-col md:flex-row md:items-center gap-6">
            <div class="w-24 h-24 bg-primary/10 rounded-3xl flex items-center justify-center text-primary text-3xl font-bold">
                {{ substr($shareholder->firstname, 0, 1) }}
            </div>
            <div class="flex-1">
                <h3 class="text-text-dark font-[900] text-2xl">{{ $shareholder->full_name }}</h3>
                <p class="text-text-muted text-sm">{{ $shareholder->email }}</p>
                <div class="mt-4 flex flex-wrap gap-2">
                    <span class="px-3 py-1 bg-success/10 text-success text-[10px] font-bold rounded-full uppercase">{{ $shareholder->status }}</span>
                    <span class="px-3 py-1 bg-gray-100 text-gray-500 text-[10px] font-bold rounded-full uppercase tracking-tighter">Member ID: #{{ substr($shareholder->id, 0, 8) }}</span>
                </div>
            </div>
            <div class="flex gap-3">
                <button @click="editModal = true" class="px-6 py-2.5 bg-gray-100 text-text-dark text-xs font-bold rounded-xl hover:bg-gray-200 transition-all">Edit Profile</button>
                <a href="{{ route('admin.shareholders.add-capital', $shareholder) }}" class="px-6 py-2.5 bg-primary text-white text-xs font-bold rounded-xl shadow-lg hover:opacity-90 transition-all">Add Capital</a>
            </div>
        </div>

        <!-- Edit Modal -->
        <div x-show="editModal" x-cloak class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div class="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl overflow-y-auto max-h-[90vh]">
                <h3 class="text-xl font-bold text-text-dark mb-6">Edit Shareholder Profile</h3>
                <form action="{{ route('admin.shareholders.update', $shareholder) }}" method="POST" class="space-y-4">
                    @csrf
                    @method('PUT')
                    <input type="hidden" name="version" value="{{ $shareholder->version }}">

                    <div class="grid grid-cols-2 gap-4">
                        <div class="space-y-1">
                            <label class="text-[10px] font-bold text-text-muted uppercase">First Name</label>
                            <input type="text" name="firstname" value="{{ $shareholder->firstname }}" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-bold text-text-muted uppercase">Last Name</label>
                            <input type="text" name="lastname" value="{{ $shareholder->lastname }}" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                        </div>
                    </div>

                    <div class="space-y-1">
                        <label class="text-[10px] font-bold text-text-muted uppercase">Email Address</label>
                        <input type="email" name="email" value="{{ $shareholder->email }}" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                    </div>

                    <div class="space-y-1">
                        <label class="text-[10px] font-bold text-text-muted uppercase">Phone Number</label>
                        <input type="text" name="contact_number" value="{{ $shareholder->contact_number }}" class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                    </div>

                    <div class="space-y-1">
                        <label class="text-[10px] font-bold text-text-muted uppercase">Home Address</label>
                        <textarea name="address" class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm h-20">{{ $shareholder->address }}</textarea>
                    </div>

                    <div class="flex gap-3 pt-4">
                        <button type="button" @click="editModal = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl">Cancel</button>
                        <button type="submit" class="flex-1 bg-primary text-white font-bold py-3 rounded-xl shadow-lg">Save Changes</button>
                    </div>
                </form>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 divide-y md:divide-y-0 md:divide-x divide-gray-100">
            <div class="p-8">
                <p class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-1">Total Share Capital</p>
                <p class="text-2xl font-[900] text-text-dark">₱{{ number_format($shareholder->total_share_capital, 2) }}</p>
            </div>
            <div class="p-8">
                <p class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-1">Active Loan Balance</p>
                <p class="text-2xl font-[900] text-error">₱{{ number_format($shareholder->loans->where('status', 'active')->sum('remaining_balance'), 2) }}</p>
            </div>
            <div class="p-8">
                <p class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-1">Credit Score</p>
                <div class="flex items-center gap-3">
                    <p class="text-2xl font-[900] text-success">{{ $shareholder->creditscore ?? 0 }}</p>
                    <div class="h-1.5 flex-1 bg-gray-100 rounded-full overflow-hidden">
                        <div class="h-full bg-success" style="width: {{ ($shareholder->creditscore ?? 0) / 10 }}%"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Contact & Address -->
        <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm p-8 space-y-6">
            <h4 class="text-text-dark font-bold text-sm">Member Information</h4>

            <div class="space-y-4">
                <div class="flex items-center gap-4">
                    <div class="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center text-gray-400">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" /></svg>
                    </div>
                    <div>
                        <p class="text-[10px] font-bold text-text-muted uppercase">Phone Number</p>
                        <p class="text-sm font-bold text-text-dark">{{ $shareholder->contact_number ?? 'Not provided' }}</p>
                    </div>
                </div>

                <div class="flex items-center gap-4">
                    <div class="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center text-gray-400">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                    </div>
                    <div>
                        <p class="text-[10px] font-bold text-text-muted uppercase">Home Address</p>
                        <p class="text-sm font-bold text-text-dark">{{ $shareholder->address ?? 'Not provided' }}</p>
                    </div>
                </div>

                <div class="flex items-center gap-4">
                    <div class="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center text-gray-400">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 00-2 2z" /></svg>
                    </div>
                    <div>
                        <p class="text-[10px] font-bold text-text-muted uppercase">Joined Date</p>
                        <p class="text-sm font-bold text-text-dark">{{ optional($shareholder->created_at)->format('M d, Y') ?? 'N/A' }}</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Recent Transactions -->
        <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
            <div class="p-8 border-b border-gray-100 flex items-center justify-between">
                <h4 class="text-text-dark font-bold text-sm">Recent Ledger Entries</h4>
                <a href="#" class="text-primary text-xs font-bold hover:underline">View Ledger</a>
            </div>
            <div class="divide-y divide-gray-50">
                @forelse($shareholder->transactions()->latest('date')->take(5)->get() as $tx)
                    <div class="p-6 flex items-center justify-between hover:bg-gray-50 transition-colors">
                        <div class="flex items-center gap-4">
                            <div class="w-10 h-10 {{ $tx->amount < 0 ? 'bg-error/10 text-error' : 'bg-success/10 text-success' }} rounded-xl flex items-center justify-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                            </div>
                            <div>
                                <p class="text-xs font-bold text-text-dark">{{ $tx->type }}</p>
                                <p class="text-[10px] text-text-muted">{{ $tx->date->format('M d, Y') }}</p>
                            </div>
                        </div>
                        <p class="text-sm font-black {{ $tx->amount < 0 ? 'text-error' : 'text-success' }}">
                            {{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}
                        </p>
                    </div>
                @empty
                    <div class="p-12 text-center text-text-muted text-sm italic">No transaction history</div>
                @endforelse
            </div>
        </div>
    </div>
</div>
@endsection
