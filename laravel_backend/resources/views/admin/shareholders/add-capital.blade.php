@extends('layouts.dashboard')

@section('title', 'Add Capital')
@section('header_title', 'Share Capital Contribution')

@section('content')
<div class="max-w-3xl mx-auto space-y-8">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <div class="flex items-center gap-4 mb-8">
            <div class="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center text-primary font-bold">
                {{ substr($shareholder->firstname, 0, 1) }}
            </div>
            <div>
                <h3 class="text-text-dark font-bold text-lg">Member: {{ $shareholder->full_name }}</h3>
                <p class="text-text-muted text-xs uppercase tracking-widest">Current Capital: ₱{{ number_format($shareholder->total_share_capital, 2) }}</p>
            </div>
        </div>

        <form action="{{ route('admin.shareholders.add-capital.store', $shareholder) }}" method="POST" class="space-y-6">
            @csrf
            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Contribution Amount</label>
                <div class="relative">
                    <span class="absolute left-4 top-4 text-text-muted font-bold">₱</span>
                    <input type="number" step="0.01" name="amount" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 pl-10 text-sm focus:ring-1 focus:ring-primary" placeholder="0.00">
                </div>
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Payment Method</label>
                <select name="method" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                    <option value="Cash">Cash</option>
                    <option value="Bank Transfer">Bank Transfer</option>
                    <option value="GCash">GCash</option>
                </select>
            </div>

            <div class="space-y-2">
                <label class="text-sm font-bold text-text-dark">Remarks / Description</label>
                <textarea name="remarks" class="w-full bg-[#F7F8FA] border-none rounded-2xl p-4 text-sm focus:ring-1 focus:ring-primary h-24" placeholder="Optional notes..."></textarea>
            </div>

            <div class="flex gap-4 pt-4">
                <a href="{{ route('admin.shareholders.show', $shareholder) }}" class="flex-1 py-4 text-center text-sm font-bold text-text-muted hover:text-text-dark">Cancel</a>
                <button type="submit" class="flex-[2] bg-primary text-white font-bold py-4 rounded-xl shadow-lg hover:opacity-90 transition-all">
                    Process Contribution
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
