@extends('layouts.dashboard')

@section('title', 'Loan Details')
@section('header_title', 'Loan Information')

@section('content')
<div class="max-w-6xl mx-auto">
    <div class="flex flex-col lg:flex-row gap-8">
        <!-- Main Details Card -->
        <div class="flex-[2] space-y-8">
            <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
                <div class="flex items-center gap-4 mb-8 pb-8 border-b border-gray-100">
                    <div class="w-14 h-14 bg-gray-100 rounded-2xl flex items-center justify-center text-gray-400">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                    </div>
                    <div>
                        <h3 class="text-text-dark font-bold text-xl">{{ $loan->shareholder->full_name }}</h3>
                        <p class="text-text-muted text-sm font-medium uppercase tracking-widest">Loan ID: #{{ substr($loan->id, 0, 8) }}</p>
                    </div>
                    <div class="ml-auto text-right">
                        <span class="px-4 py-1.5 bg-success/10 text-success text-xs font-bold rounded-full uppercase tracking-tighter">{{ $loan->status }}</span>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
                    <div class="flex justify-between items-center py-1">
                        <span class="text-text-muted text-sm">Principal Amount</span>
                        <span class="text-text-dark font-bold">₱{{ number_format($loan->amount, 2) }}</span>
                    </div>
                    <div class="flex justify-between items-center py-1">
                        <span class="text-text-muted text-sm">Interest Rate</span>
                        <span class="text-text-dark font-bold">{{ $loan->interest_rate }}%</span>
                    </div>
                    <div class="flex justify-between items-center py-1">
                        <span class="text-text-muted text-sm">Loan Tenure</span>
                        <span class="text-text-dark font-bold">{{ $loan->loanRequest->months ?? 'N/A' }} Months</span>
                    </div>
                    <div class="flex justify-between items-center py-1">
                        <span class="text-text-muted text-sm">Disbursement Date</span>
                        <span class="text-text-dark font-bold">{{ optional($loan->date_disbursed)->format('M d, Y') ?? 'N/A' }}</span>
                    </div>
                    <div class="flex justify-between items-center py-1">
                        <span class="text-text-muted text-sm">Processing Fee (5%)</span>
                        <span class="text-text-dark font-bold">₱{{ number_format($loan->amount * 0.05, 2) }}</span>
                    </div>
                    <div class="flex justify-between items-center py-1">
                        <span class="text-text-muted text-sm font-bold">Remaining Balance</span>
                        <span class="text-error font-[900]">₱{{ number_format($loan->remaining_balance ?? $loan->amount, 2) }}</span>
                    </div>
                </div>

                <div class="mt-12">
                    <h4 class="text-text-dark font-bold text-sm mb-4">Co-makers</h4>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        @php $comakers = is_array($loan->loanRequest?->loan_comakers) ? $loan->loanRequest->loan_comakers : []; @endphp
                        @forelse($comakers as $cmId)
                            @php $cm = \App\Models\Shareholder::find($cmId); @endphp
                            <div class="p-4 bg-[#F7F8FA] rounded-2xl flex items-center justify-between">
                                <span class="text-sm font-bold text-text-dark">{{ $cm->full_name ?? 'Unknown' }}</span>
                                <span class="text-[10px] font-bold text-success uppercase">Approved</span>
                            </div>
                        @empty
                            <p class="text-text-muted text-sm italic">No co-makers listed</p>
                        @endforelse
                    </div>
                </div>
            </div>
        </div>

        <!-- Sidebar / Actions -->
        <div class="flex-1 space-y-8">
            <div class="bg-[#32211A] rounded-3xl p-8 shadow-xl text-white">
                <h4 class="text-white/50 text-xs font-bold uppercase tracking-widest mb-6">Quick Actions</h4>

                <div class="space-y-4">
                    <a href="{{ route('admin.loans.payment', $loan) }}" class="flex items-center gap-4 group p-2 -ml-2 rounded-xl hover:bg-white/5 transition-all">
                        <div class="w-10 h-10 bg-primary/20 rounded-xl flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" /></svg>
                        </div>
                        <span class="text-sm font-bold">Record Payment</span>
                    </a>

                    <button class="w-full flex items-center gap-4 group p-2 -ml-2 rounded-xl hover:bg-white/5 transition-all">
                        <div class="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center text-white group-hover:scale-110 transition-transform">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 01-2-2H9a2 2 0 01-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" /></svg>
                        </div>
                        <span class="text-sm font-bold">Print Statement</span>
                    </button>
                </div>

                <div class="mt-12 pt-8 border-t border-white/10">
                    <h4 class="text-white font-bold text-sm mb-6">Payment History</h4>
                    <div class="space-y-6">
                        @forelse($loan->transactions->where('type', 'Loan Payment') as $tx)
                            <div class="flex justify-between items-center">
                                <div>
                                    <p class="text-xs font-bold">{{ $tx->date->format('M d, Y') }}</p>
                                    <p class="text-[10px] text-white/50 uppercase tracking-tighter">{{ $tx->method }}</p>
                                </div>
                                <p class="text-sm font-[900]">₱{{ number_format($tx->amount, 2) }}</p>
                            </div>
                        @empty
                            <p class="text-white/40 text-xs italic text-center py-4">No payments recorded yet</p>
                        @endforelse
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
