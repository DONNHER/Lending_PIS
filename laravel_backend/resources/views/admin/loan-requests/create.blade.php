@extends('layouts.dashboard')

@section('title', 'Admin: Add Loan')
@section('header_title', 'Create Loan Request')

@section('content')
<div class="max-w-4xl mx-auto space-y-8" x-data="loanCalculator({{ $interestRate }})">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <form action="{{ route('admin.loan-requests.store') }}" method="POST" class="space-y-8">
            @csrf

            <!-- Step 1: Select Borrower -->
            <div class="space-y-4">
                <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 1</span>
                    <h3 class="text-text-dark font-bold text-sm">Select Borrower</h3>
                </div>
                <select name="shareholder_id" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                    <option value="">Search borrower...</option>
                    @foreach($shareholders as $s)
                        <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Step 2: Amount -->
            <div class="space-y-4">
                <div class="flex justify-between items-end">
                    <div class="flex items-center gap-2">
                        <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 2</span>
                        <h3 class="text-text-dark font-bold text-sm">Loan Amount</h3>
                    </div>
                    <span class="text-3xl font-[900] text-text-dark">₱<span x-text="formatCurrency(amount)"></span></span>
                </div>
                <input type="range" name="amount" x-model="amount" min="500" max="10000" step="500" class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-primary">
                <div class="flex justify-between text-[10px] text-text-muted font-bold">
                    <span>MIN ₱500</span>
                    <span>MAX ₱10,000</span>
                </div>
            </div>

            <!-- Step 3: Duration -->
            <div class="space-y-4">
                <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 3</span>
                    <h3 class="text-text-dark font-bold text-sm">Select Duration</h3>
                </div>
                <div class="flex flex-wrap gap-3">
                    <template x-for="mo in [1, 2, 3, 4, 5, 6, 12]">
                        <button type="button" @click="months = mo" :class="months == mo ? 'bg-primary text-white shadow-lg' : 'bg-white text-text-dark border-gray-200'" class="px-6 py-2 rounded-xl text-xs font-bold border transition-all">
                            <span x-text="mo < 12 ? mo + ' Mo' : '1 Year'"></span>
                        </button>
                    </template>
                    <input type="hidden" name="months" :value="months">
                </div>
            </div>

            <!-- Step 4: Purpose -->
            <div class="space-y-4">
                <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 4</span>
                    <h3 class="text-text-dark font-bold text-sm">Loan Purpose</h3>
                </div>
                <select name="purpose" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                    <option value="Educational">Educational</option>
                    <option value="Medical">Medical</option>
                    <option value="Business">Business</option>
                    <option value="Emergency">Emergency</option>
                    <option value="Other">Other</option>
                </select>
            </div>

            <!-- Step 5: Co-makers -->
            <div class="space-y-4">
                <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 5</span>
                    <h3 class="text-text-dark font-bold text-sm">Select 2 Co-makers</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <select name="comakers[]" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                        <option value="">Select first co-maker...</option>
                        @foreach($shareholders as $s)
                            <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                        @endforeach
                    </select>
                    <select name="comakers[]" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                        <option value="">Select second co-maker...</option>
                        @foreach($shareholders as $s)
                            <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <!-- Summary -->
            <div class="bg-primary/5 p-8 rounded-[32px] border border-primary/10 space-y-6">
                <div class="flex justify-between items-center">
                    <span class="text-text-muted font-bold text-xs uppercase tracking-widest">Monthly Installment</span>
                    <span class="text-2xl font-black text-primary">₱<span x-text="formatCurrency(monthlyAmortization)"></span></span>
                </div>
                <div class="h-px bg-primary/10"></div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <p class="text-[10px] text-text-muted uppercase font-bold mb-1">Total Repayable</p>
                        <p class="text-sm font-bold text-text-dark">₱<span x-text="formatCurrency(totalRepayable)"></span></p>
                    </div>
                    <div class="text-right">
                        <p class="text-[10px] text-text-muted uppercase font-bold mb-1">Processing Fee (5%)</p>
                        <p class="text-sm font-bold text-error">- ₱<span x-text="formatCurrency(processingFee)"></span></p>
                    </div>
                </div>
            </div>

            <button type="submit" class="w-full bg-primary text-white font-[900] py-5 rounded-2xl shadow-xl hover:opacity-90 transition-all text-lg">
                Create Loan Request
            </button>
        </form>
    </div>
</div>

@push('scripts')
<script>
function loanCalculator(interestRate) {
    return {
        amount: 5000,
        months: 1,
        interestRate: interestRate,
        get totalInterest() {
            return (this.amount * (this.interestRate / 100)) * this.months;
        },
        get processingFee() {
            return this.amount * 0.05;
        },
        get totalRepayable() {
            return parseFloat(this.amount) + parseFloat(this.totalInterest);
        },
        get monthlyAmortization() {
            return this.totalRepayable / this.months;
        },
        formatCurrency(val) {
            return new Intl.NumberFormat('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(val);
        }
    }
}
</script>
@endpush
@endsection
