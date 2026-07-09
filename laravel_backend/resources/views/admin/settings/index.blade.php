@extends('layouts.dashboard')

@section('title', 'Lending Settings')
@section('header_title', 'Lending Configuration')

@section('content')
<div class="max-w-4xl space-y-8">
    <!-- Interest Rate Configuration -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-[#F0F1F5] flex justify-between items-center">
            <div>
                <h3 class="text-text-dark font-bold text-lg">Standard Interest Rate</h3>
                <p class="text-text-muted text-sm">Set the global interest rate for new loan applications</p>
            </div>
            <div class="bg-primary/10 px-4 py-2 rounded-2xl">
                <span class="text-primary font-[800] text-xl">{{ $interestRate->rate ?? '0' }}%</span>
            </div>
        </div>

        <form action="{{ route('admin.settings.interest') }}" method="POST" class="p-8 space-y-6">
            @csrf
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">New Interest Rate (%)</label>
                    <div class="relative">
                        <input type="number" step="0.01" name="rate" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary" placeholder="e.g. 5.00">
                        <span class="absolute right-4 top-4 text-text-muted font-bold">%</span>
                    </div>
                </div>
                <div class="space-y-2">
                    <label class="text-sm font-bold text-text-dark">Effective Date</label>
                    <input type="date" name="effective_date" value="{{ date('Y-m-d') }}" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                </div>
            </div>

            <div class="flex justify-end pt-4">
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-xl shadow-lg hover:opacity-90 transition-all">
                    Update Rate
                </button>
            </div>
        </form>
    </div>

    <!-- System Info Card -->
    <div class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm flex items-center gap-6">
        <div class="w-16 h-16 bg-success/10 rounded-2xl flex items-center justify-center text-success">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
        </div>
        <div>
            <h4 class="text-text-dark font-bold">Lending Policy Active</h4>
            <p class="text-text-muted text-xs">Last updated by admin on {{ optional($interestRate)->created_at ? $interestRate->created_at->format('M d, Y') : 'N/A' }}</p>
        </div>
    </div>
</div>
@endsection
