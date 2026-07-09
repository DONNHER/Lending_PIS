@extends('layouts.dashboard')

@section('title', 'Evaluate Loan')
@section('header_title', 'Loan Evaluation')

@section('content')
<div class="max-w-4xl mx-auto space-y-8">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <div class="flex items-center justify-between mb-8">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center text-primary text-xl font-bold">
                    {{ substr($loanRequest->shareholder->firstname, 0, 1) }}
                </div>
                <div>
                    <h3 class="text-text-dark font-bold text-lg">{{ $loanRequest->shareholder->full_name }}</h3>
                    <p class="text-text-muted text-sm">Application Date: {{ $loanRequest->created_at->format('M d, Y') }}</p>
                </div>
            </div>
            <div class="text-right">
                <p class="text-[10px] font-bold text-text-muted uppercase tracking-widest">Requested Principal</p>
                <p class="text-2xl font-[900] text-primary">₱{{ number_format($loanRequest->requested_amount, 2) }}</p>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-[#F7F8FA] p-4 rounded-2xl">
                <p class="text-[10px] font-bold text-text-muted uppercase mb-1">Interest Rate</p>
                <p class="text-sm font-bold text-text-dark">{{ $loanRequest->interest_rate }}%</p>
            </div>
            <div class="bg-[#F7F8FA] p-4 rounded-2xl">
                <p class="text-[10px] font-bold text-text-muted uppercase mb-1">Credit Score</p>
                <p class="text-sm font-bold text-text-dark">{{ $loanRequest->shareholder->creditscore ?? '0' }}</p>
            </div>
            <div class="bg-[#F7F8FA] p-4 rounded-2xl">
                <p class="text-[10px] font-bold text-text-muted uppercase mb-1">Share Capital</p>
                <p class="text-sm font-bold text-success">₱{{ number_format($loanRequest->shareholder->total_share_capital, 2) }}</p>
            </div>
        </div>

        <!-- Co-maker Decisions -->
        <div class="mb-10">
            <h4 class="text-text-dark font-bold text-sm mb-4">Co-maker Status</h4>
            <div class="space-y-3">
                @php
                    $comakers = is_array($loanRequest->loan_comakers) ? $loanRequest->loan_comakers : [];
                    $decisions = is_array($loanRequest->comaker_decisions) ? $loanRequest->comaker_decisions : [];
                @endphp
                @forelse($comakers as $cmId)
                    @php $cm = \App\Models\Shareholder::find($cmId); @endphp
                    <div class="flex items-center justify-between p-4 bg-gray-50 rounded-2xl border border-gray-100">
                        <span class="text-sm font-medium text-text-dark">{{ $cm->full_name ?? 'Unknown' }}</span>
                        @if(isset($decisions[$cmId]))
                            <span class="px-3 py-1 rounded-full text-[9px] font-bold uppercase {{ $decisions[$cmId] === 'approved' ? 'bg-success/10 text-success' : 'bg-error/10 text-error' }}">
                                {{ $decisions[$cmId] }}
                            </span>
                        @else
                            <span class="px-3 py-1 bg-warning/10 text-warning text-[9px] font-bold rounded-full uppercase">Pending</span>
                        @endif
                    </div>
                @empty
                    <p class="text-text-muted text-xs italic">No co-makers assigned</p>
                @endforelse
            </div>
        </div>

        <div class="space-y-4">
            <h4 class="text-text-dark font-bold text-sm">Review Decision</h4>
            <form action="{{ route('admin.loan-requests.update', $loanRequest) }}" method="POST" class="space-y-6">
                @csrf
                <div class="flex gap-4">
                    <label class="flex-1 cursor-pointer group">
                        <input type="radio" name="status" value="approved" required class="peer sr-only">
                        <div class="p-4 border-2 border-gray-100 rounded-2xl flex items-center gap-3 peer-checked:border-success peer-checked:bg-success/5 transition-all">
                            <div class="w-6 h-6 rounded-full border-2 border-gray-200 peer-checked:border-success flex items-center justify-center">
                                <div class="w-3 h-3 rounded-full bg-success opacity-0 peer-checked:opacity-100"></div>
                            </div>
                            <span class="text-sm font-bold text-text-dark">Approve</span>
                        </div>
                    </label>
                    <label class="flex-1 cursor-pointer group">
                        <input type="radio" name="status" value="rejected" required class="peer sr-only">
                        <div class="p-4 border-2 border-gray-100 rounded-2xl flex items-center gap-3 peer-checked:border-error peer-checked:bg-error/5 transition-all">
                            <div class="w-6 h-6 rounded-full border-2 border-gray-200 peer-checked:border-error flex items-center justify-center">
                                <div class="w-3 h-3 rounded-full bg-error opacity-0 peer-checked:opacity-100"></div>
                            </div>
                            <span class="text-sm font-bold text-text-dark">Reject</span>
                        </div>
                    </label>
                </div>

                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Remarks / Notes</label>
                    <textarea name="remarks" class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary h-32" placeholder="Optional notes for the applicant..."></textarea>
                </div>

                <div class="flex gap-4 pt-4">
                    <a href="{{ route('admin.loan-requests.index') }}" class="flex-1 py-4 text-center text-sm font-bold text-text-muted hover:text-text-dark">Cancel</a>
                    <button type="submit" class="flex-[2] bg-primary text-white font-bold py-4 rounded-xl shadow-lg hover:opacity-90 transition-all">
                        Finalize Review
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
