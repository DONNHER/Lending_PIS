@extends('layouts.dashboard')

@section('title', 'Record Payment')
@section('header_title', 'Process Loan Payment')

@section('content')
<div class="max-w-6xl mx-auto">
    <form action="{{ route('admin.loans.payment.store', $loan) }}" method="POST" x-data="paymentProcessor({{ $loan->remaining_balance ?? $loan->amount }})">
        @csrf
        <div class="flex flex-col lg:flex-row gap-8">
            <!-- Form Side -->
            <div class="flex-[2] space-y-8">
                <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
                    <div class="flex items-center gap-4 mb-8">
                        <div class="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center text-primary font-bold">
                            {{ substr($loan->shareholder->firstname, 0, 1) }}
                        </div>
                        <div>
                            <h3 class="text-text-dark font-bold">Borrower: {{ $loan->shareholder->full_name }}</h3>
                            <p class="text-text-muted text-xs uppercase tracking-widest">Loan ID: #{{ substr($loan->id, 0, 8) }}</p>
                        </div>
                    </div>

                    <div class="space-y-6">
                        <div class="space-y-2">
                            <label class="text-sm font-bold text-text-dark">Payment Amount</label>
                            <div class="relative">
                                <span class="absolute left-4 top-4 text-text-muted font-bold">₱</span>
                                <input type="number" step="0.01" name="amount" x-model="amount" @input="validate" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 pl-10 text-sm focus:ring-1 focus:ring-primary" placeholder="0.00">
                            </div>
                            <p class="text-[10px] text-text-muted">
                                Max allowable: <span class="font-bold text-text-dark">₱{{ number_format($loan->remaining_balance ?? $loan->amount, 2) }}</span>
                            </p>
                        </div>

                        <div class="space-y-2">
                            <label class="text-sm font-bold text-text-dark">Payment Method</label>
                            <select name="method" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                                <option value="Cash">Cash</option>
                                <option value="Bank Transfer">Bank Transfer</option>
                                <option value="GCash">GCash</option>
                                <option value="Salary Deduction">Salary Deduction</option>
                            </select>
                        </div>

                        <div class="bg-primary/5 p-6 rounded-2xl border border-primary/10">
                            <h4 class="text-[10px] font-bold text-primary uppercase tracking-widest mb-3">Installment Target</h4>
                            <div class="flex justify-between items-center">
                                <span class="text-sm text-text-muted">Monthly Amortization</span>
                                <span class="text-lg font-[900] text-primary">₱{{ number_format($loan->monthly_amortization ?? ($loan->amount / ($loan->loanRequest->months ?? 1)), 2) }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="flex justify-end gap-4">
                    <a href="{{ route('admin.loans.show', $loan) }}" class="px-8 py-4 text-sm font-bold text-text-muted hover:text-text-dark transition-all">Cancel</a>
                    <button type="submit" :disabled="!isValid" :class="!isValid ? 'opacity-50 cursor-not-allowed' : 'hover:opacity-90'" class="bg-primary text-white font-bold px-12 py-4 rounded-xl shadow-xl transition-all">
                        Confirm Payment
                    </button>
                </div>
            </div>

            <!-- Ledger Summary -->
            <div class="flex-1">
                <div class="bg-[#32211A] rounded-3xl p-8 shadow-xl text-white">
                    <h4 class="text-white/50 text-xs font-bold uppercase tracking-widest mb-8">Ledger Summary</h4>

                    <div class="space-y-6">
                        <div class="flex justify-between items-center text-sm">
                            <span class="text-white/60">Principal</span>
                            <span class="font-bold">₱{{ number_format($loan->amount, 2) }}</span>
                        </div>
                        <div class="h-px bg-white/10"></div>
                        <div class="flex justify-between items-center text-sm">
                            <span class="text-white/60">Total Interest</span>
                            <span class="font-bold">₱{{ number_format($loan->amount * ($loan->interest_rate / 100) * ($loan->loanRequest->months ?? 1), 2) }}</span>
                        </div>
                        <div class="h-px bg-white/10"></div>
                        <div class="flex justify-between items-center text-sm">
                            <span class="text-white/60">Total Repayable</span>
                            <span class="font-bold">₱{{ number_format($loan->amount + ($loan->amount * ($loan->interest_rate / 100) * ($loan->loanRequest->months ?? 1)), 2) }}</span>
                        </div>
                        <div class="mt-12 pt-8 border-t border-white/20">
                            <div class="flex justify-between items-center">
                                <span class="text-white/50 text-xs font-bold uppercase">Outstanding</span>
                                <span class="text-2xl font-[900] text-primary">₱{{ number_format($loan->remaining_balance ?? $loan->amount, 2) }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<script>
function paymentProcessor(maxAmount) {
    return {
        amount: '',
        max: maxAmount,
        isValid: false,
        validate() {
            const val = parseFloat(this.amount);
            this.isValid = !isNaN(val) && val > 0 && val <= (this.max + 0.01);
        }
    }
}
</script>
@endpush
@endsection
