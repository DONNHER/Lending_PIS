@extends('layouts.dashboard')

@section('title', 'My Portal')
@section('header_title', 'Shareholder Portal')

@section('content')
<div class="space-y-8">
    <!-- Quick Stats for Shareholder -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-primary p-6 rounded-3xl shadow-[0_8px_30px_rgb(255,111,0,0.2)] text-white relative overflow-hidden">
            <div class="relative z-10">
                <h4 class="text-white/70 text-xs font-bold uppercase tracking-wider">Total Share Capital</h4>
                <p class="text-3xl font-[900] mt-2">₱{{ number_format($shareholder->total_share_capital ?? 0, 2) }}</p>
                <div class="mt-4 flex items-center gap-2">
                    <span class="text-[10px] bg-white/20 px-2 py-1 rounded-lg">Member since {{ optional($shareholder->created_at)->format('Y') ?? 'N/A' }}</span>
                </div>
            </div>
            <div class="absolute -right-4 -bottom-4 opacity-10">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-32 w-32" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            </div>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Active Loan Balance</h4>
            <p class="text-text-dark text-2xl font-[800] mt-2">₱{{ number_format($activeLoanBalance, 2) }}</p>
            <div class="mt-4 flex items-center justify-between">
                <span class="text-[11px] text-text-muted">Next Due: <span class="text-text-dark font-bold">{{ $activeLoans->first()?->next_repayment_date?->format('M d, Y') ?? 'N/A' }}</span></span>
            </div>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Actions</h4>
            <div class="grid grid-cols-2 gap-3 mt-4">
                <a href="{{ route('shareholder.loan.apply') }}" class="flex flex-col items-center gap-1.5 p-3 bg-primary/5 rounded-2xl group hover:bg-primary transition-all">
                    <div class="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary group-hover:bg-white/20 group-hover:text-white">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
                    </div>
                    <span class="text-[9px] font-black uppercase text-primary group-hover:text-white">Apply Loan</span>
                </a>
                <a href="{{ route('shareholder.loan.comaker.requests') }}" class="flex flex-col items-center gap-1.5 p-3 bg-gray-50 rounded-2xl group hover:bg-text-dark transition-all">
                    <div class="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-400 group-hover:bg-white/20 group-hover:text-white">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                    </div>
                    <span class="text-[9px] font-black uppercase text-text-muted group-hover:text-white">Signatures</span>
                </a>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Recent Transactions -->
        <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
            <div class="p-6 border-b border-[#F0F1F5] flex items-center justify-between">
                <h4 class="text-text-dark font-bold">My Ledger</h4>
                <a href="{{ route('notifications.index') }}" class="text-primary text-xs font-bold">View History</a>
            </div>
            <div class="divide-y divide-[#F0F1F5]">
                @forelse($recentTransactions as $tx)
                    <div class="p-5 flex items-center justify-between hover:bg-gray-50 transition-colors">
                        <div class="flex items-center gap-4">
                            <div class="w-10 h-10 {{ $tx->amount < 0 ? 'bg-error/10 text-error' : 'bg-success/10 text-success' }} rounded-xl flex items-center justify-center">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                            </div>
                            <div>
                                <h5 class="text-sm font-bold text-text-dark">{{ $tx->type }}</h5>
                                <p class="text-[10px] text-text-muted">{{ $tx->date->format('M d, Y') }}</p>
                            </div>
                        </div>
                        <p class="text-sm font-black {{ $tx->amount < 0 ? 'text-error' : 'text-success' }}">
                            {{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}
                        </p>
                    </div>
                @empty
                    <div class="p-10 text-center text-text-muted italic text-sm">No recent activity</div>
                @endforelse
            </div>
        </div>

        <!-- Loan Overview -->
        <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm p-6">
            <h4 class="text-text-dark font-bold mb-6">Current Loan Information</h4>

            <div class="space-y-6">
                @forelse($activeLoans as $loan)
                    <div class="bg-[#F7F8FA] p-6 rounded-3xl border border-gray-100">
                        <div class="flex justify-between items-start mb-6">
                            <div>
                                <p class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-1">Principal Amount</p>
                                <h5 class="text-2xl font-black text-text-dark">₱{{ number_format($loan->principal_amount, 2) }}</h5>
                            </div>
                            <span class="px-4 py-1.5 bg-primary text-white text-[9px] font-bold rounded-full uppercase tracking-tighter shadow-md shadow-primary/20">{{ $loan->status }}</span>
                        </div>

                        <div class="grid grid-cols-2 gap-4 border-t border-gray-200 pt-6">
                            <div>
                                <p class="text-[9px] text-text-muted font-bold uppercase tracking-widest">Remaining Balance</p>
                                <p class="text-lg font-black text-error">₱{{ number_format($loan->remaining_balance, 2) }}</p>
                            </div>
                            <div class="text-right">
                                <p class="text-[9px] text-text-muted font-bold uppercase tracking-widest">Monthly Installment</p>
                                <p class="text-lg font-black text-text-dark">₱{{ number_format($loan->monthly_amortization, 2) }}</p>
                            </div>
                        </div>

                        <div class="mt-6 flex justify-center">
                            <p class="text-[10px] font-bold text-text-muted uppercase">Next Payment Due: <span class="text-text-dark underline decoration-primary decoration-2">{{ $loan->next_repayment_date->format('M d, Y') }}</span></p>
                        </div>
                    </div>
                @empty
                    <div class="h-full flex flex-col items-center justify-center py-10">
                        <div class="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center text-gray-300 mb-4">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                        </div>
                        <p class="text-text-muted text-sm font-medium">No active loans found</p>
                        <a href="{{ route('shareholder.loan.apply') }}" class="mt-4 bg-primary/10 text-primary px-8 py-3 rounded-2xl text-xs font-bold hover:bg-primary hover:text-white transition-all shadow-lg shadow-primary/10">Apply for a Loan</a>
                    </div>
                @endforelse
            </div>
        </div>
    </div>
</div>
@endsection
