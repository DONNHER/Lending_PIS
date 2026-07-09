@extends('layouts.dashboard')

@section('title', 'Apply for Loan')
@section('header_title', 'New Loan Application')

@section('content')
<div class="max-w-4xl mx-auto space-y-8" x-data="loanCalculator({{ $interestRate }})">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <div class="mb-8">
            <h3 class="text-text-dark font-[900] text-xl">Lending Terms</h3>
            <p class="text-text-muted text-sm mt-1">Please configure your loan request below</p>
        </div>

        <form action="{{ route('shareholder.loan.store') }}" method="POST" class="space-y-10">
            @csrf

            <!-- Amount Selection -->
            <div class="space-y-4">
                <div class="flex justify-between items-end">
                    <h4 class="text-sm font-bold text-text-dark uppercase tracking-wider">How much do you need?</h4>
                    <span class="text-3xl font-black text-primary">₱<span x-text="formatCurrency(amount)"></span></span>
                </div>
                <input type="range" name="amount" x-model="amount" min="500" max="10000" step="100" class="w-full h-2 bg-gray-100 rounded-lg appearance-none cursor-pointer accent-primary">
                <div class="flex justify-between text-[10px] text-text-muted font-bold">
                    <span>MIN ₱500</span>
                    <span>MAX ₱10,000</span>
                </div>
            </div>

            <!-- Duration Selection -->
            <div class="space-y-4">
                <h4 class="text-sm font-bold text-text-dark uppercase tracking-wider">Repayment Period</h4>
                <div class="flex flex-wrap gap-3">
                    <template x-for="mo in [1, 2, 3, 4, 5, 6, 12]">
                        <button type="button" @click="months = mo" :class="months == mo ? 'bg-primary text-white shadow-lg' : 'bg-gray-50 text-text-muted'" class="px-6 py-2.5 rounded-xl text-xs font-bold transition-all">
                            <span x-text="mo < 12 ? mo + ' Months' : '1 Year'"></span>
                        </button>
                    </template>
                    <input type="hidden" name="months" :value="months">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <!-- Purpose -->
                <div class="space-y-4">
                    <h4 class="text-sm font-bold text-text-dark uppercase tracking-wider">Purpose</h4>
                    <select name="purpose" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                        <option value="Educational">Educational</option>
                        <option value="Medical">Medical</option>
                        <option value="Business">Business</option>
                        <option value="Emergency">Emergency</option>
                        <option value="Other">Other</option>
                    </select>
                </div>

                <!-- Co-makers -->
                <div class="space-y-4">
                    <h4 class="text-sm font-bold text-text-dark uppercase tracking-wider">Select 2 Co-makers</h4>
                    <div class="space-y-3">
                        <select name="comakers[]" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                            <option value="">Choose co-maker 1...</option>
                            @foreach($otherShareholders as $s)
                                <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                            @endforeach
                        </select>
                        <select name="comakers[]" required class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary">
                            <option value="">Choose co-maker 2...</option>
                            @foreach($otherShareholders as $s)
                                <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>
            </div>

            <!-- Summary Card -->
            <div class="bg-[#32211A] rounded-3xl p-8 text-white space-y-6">
                <div class="flex justify-between items-center">
                    <span class="text-white/60 text-sm">Monthly Installment</span>
                    <span class="text-2xl font-black">₱<span x-text="formatCurrency(monthlyAmortization)"></span></span>
                </div>
                <div class="h-px bg-white/10"></div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <p class="text-[10px] text-white/40 uppercase font-bold mb-1">Total Repayable</p>
                        <p class="text-sm font-bold">₱<span x-text="formatCurrency(totalRepayable)"></span></p>
                    </div>
                    <div class="text-right">
                        <p class="text-[10px] text-white/40 uppercase font-bold mb-1">Processing Fee (5%)</p>
                        <p class="text-sm font-bold text-primary">₱<span x-text="formatCurrency(processingFee)"></span></p>
                    </div>
                </div>
            </div>

            <button type="submit" class="w-full bg-primary text-white font-black py-5 rounded-2xl shadow-xl hover:opacity-90 transition-all text-lg">
                Submit Application
            </button>
        </form>
    </div>
</div>

@push('scripts')
<script>
function loanCalculator(interestRate) {
    return {
        amount: 3000,
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
