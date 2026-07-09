@extends('layouts.dashboard')

@section('title', 'Co-maker Requests')
@section('header_title', 'Co-maker Signatures')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">
    <div class="flex items-center justify-between mb-2">
        <h3 class="text-text-dark font-[900] text-xl">Pending Signatures</h3>
        <span class="px-3 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-full uppercase">{{ $requests->count() }} Request(s)</span>
    </div>

    <div class="space-y-4">
        @forelse($requests as $req)
            @php
                $myDecision = $req->comaker_decisions[$shareholder->id] ?? null;
            @endphp
            <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-6 transition-all hover:border-primary/20">
                <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div class="flex items-center gap-4">
                        <div class="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center text-primary font-bold">
                            {{ substr($req->shareholder->firstname, 0, 1) }}
                        </div>
                        <div>
                            <h4 class="text-text-dark font-bold">{{ $req->shareholder->full_name }}</h4>
                            <p class="text-text-muted text-xs">Is applying for a loan of <span class="text-text-dark font-bold">₱{{ number_format($req->requested_amount, 2) }}</span></p>
                        </div>
                    </div>

                    @if(!$myDecision)
                        <div class="flex items-center gap-3">
                            <form action="{{ route('shareholder.loan.comaker.sign', $req) }}" method="POST">
                                @csrf
                                <input type="hidden" name="decision" value="rejected">
                                <button type="submit" class="px-6 py-2.5 text-xs font-bold text-error hover:bg-error/5 rounded-xl transition-all">Decline</button>
                            </form>
                            <form action="{{ route('shareholder.loan.comaker.sign', $req) }}" method="POST">
                                @csrf
                                <input type="hidden" name="decision" value="approved">
                                <button type="submit" class="px-8 py-2.5 bg-primary text-white text-xs font-bold rounded-xl shadow-lg hover:opacity-90 transition-all">Accept Responsibility</button>
                            </form>
                        </div>
                    @else
                        <div class="flex items-center gap-2 px-4 py-2 {{ $myDecision === 'approved' ? 'bg-success/10 text-success' : 'bg-error/10 text-error' }} rounded-xl">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $myDecision === 'approved' ? 'M5 13l4 4L19 7' : 'M6 18L18 6M6 6l12 12' }}" />
                            </svg>
                            <span class="text-[10px] font-bold uppercase tracking-wider">You {{ $myDecision }} this</span>
                        </div>
                    @endif
                </div>

                <div class="mt-6 pt-6 border-t border-gray-50 grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div>
                        <p class="text-[9px] text-text-muted font-bold uppercase">Repayment</p>
                        <p class="text-xs font-bold text-text-dark">{{ $req->months }} Months</p>
                    </div>
                    <div>
                        <p class="text-[9px] text-text-muted font-bold uppercase">Interest</p>
                        <p class="text-xs font-bold text-text-dark">{{ $req->interest_rate }}%</p>
                    </div>
                    <div>
                        <p class="text-[9px] text-text-muted font-bold uppercase">Purpose</p>
                        <p class="text-xs font-bold text-text-dark">{{ $req->purpose }}</p>
                    </div>
                    <div class="text-right">
                        <p class="text-[9px] text-text-muted font-bold uppercase">Applied On</p>
                        <p class="text-xs font-bold text-text-dark">{{ $req->created_at->format('M d, Y') }}</p>
                    </div>
                </div>
            </div>
        @empty
            <div class="bg-white rounded-3xl border-2 border-dashed border-gray-100 p-12 text-center">
                <div class="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4 text-gray-300">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                </div>
                <h4 class="text-text-dark font-bold">No requests found</h4>
                <p class="text-text-muted text-xs mt-1">You're all caught up with your co-maker duties.</p>
            </div>
        @endforelse
    </div>
</div>
@endsection
