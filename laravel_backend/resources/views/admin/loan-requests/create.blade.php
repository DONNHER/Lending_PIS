@extends('layouts.dashboard')

@section('title', 'Admin: Add Loan')
@section('header_title', 'Create Loan Request')

@section('content')
<div class="max-w-4xl mx-auto space-y-8" x-data="loanCalculator({{ $interestRate }})" @beforeunload.window="if(isDirty) $event.returnValue = 'You have unsaved changes.'">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <form action="{{ route('admin.loan-requests.store') }}" method="POST" class="space-y-8" @submit="loading = true" @change="isDirty = true">
            @csrf

            <!-- Step 1: Select Borrower -->
            <div class="space-y-4">
                <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 1</span>
                    <h3 class="text-text-dark font-bold text-sm">Select Borrower <span class="text-error" aria-hidden="true">*</span></h3>
                </div>
                <select name="shareholder_id" required
                    @blur="validateField('shareholder_id')"
                    class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('shareholder_id') ring-1 ring-error @enderror">
                    <option value="">Search borrower...</option>
                    @foreach($shareholders as $s)
                        <option value="{{ $s->id }}" {{ old('shareholder_id') == $s->id ? 'selected' : '' }}>{{ $s->full_name }}</option>
                    @endforeach
                </select>
                <p x-show="errors.shareholder_id" class="text-[10px] text-error font-bold" role="alert" x-text="errors.shareholder_id"></p>
                @error('shareholder_id') <p class="text-[10px] text-error font-bold" role="alert">{{ $message }}</p> @enderror
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
                    <h3 class="text-text-dark font-bold text-sm">Loan Purpose <span class="text-error" aria-hidden="true">*</span></h3>
                </div>
                <select name="purpose" required x-model="purpose"
                    @blur="validateField('purpose')"
                    class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('purpose') ring-1 ring-error @enderror">
                    <option value="Educational" {{ old('purpose') == 'Educational' ? 'selected' : '' }}>Educational</option>
                    <option value="Medical" {{ old('purpose') == 'Medical' ? 'selected' : '' }}>Medical</option>
                    <option value="Business" {{ old('purpose') == 'Business' ? 'selected' : '' }}>Business</option>
                    <option value="Emergency" {{ old('purpose') == 'Emergency' ? 'selected' : '' }}>Emergency</option>
                    <option value="Other" {{ old('purpose') == 'Other' ? 'selected' : '' }}>Other</option>
                </select>
                <p x-show="errors.purpose" class="text-[10px] text-error font-bold" role="alert" x-text="errors.purpose"></p>
                @error('purpose') <p class="text-[10px] text-error font-bold" role="alert">{{ $message }}</p> @enderror
            </div>

            <!-- Step 5: Co-makers -->
            <div class="space-y-4">
                <div class="flex items-center gap-2">
                    <span class="px-2 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-lg uppercase">Step 5</span>
                    <h3 class="text-text-dark font-bold text-sm">Select 2 Co-makers <span class="text-error" aria-hidden="true">*</span></h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="space-y-1">
                        <select name="comakers[]" required x-model="comakers[0]"
                            @blur="validateField('comakers')"
                            class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('comakers.0') ring-1 ring-error @enderror">
                            <option value="">Select first co-maker...</option>
                            @foreach($shareholders as $s)
                                <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                            @endforeach
                        </select>
                        @error('comakers.0') <p class="text-[10px] text-error font-bold" role="alert">{{ $message }}</p> @enderror
                    </div>
                    <div class="space-y-1">
                        <select name="comakers[]" required x-model="comakers[1]"
                            @blur="validateField('comakers')"
                            class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-primary @error('comakers.1') ring-1 ring-error @enderror">
                            <option value="">Select second co-maker...</option>
                            @foreach($shareholders as $s)
                                <option value="{{ $s->id }}">{{ $s->full_name }}</option>
                            @endforeach
                        </select>
                        @error('comakers.1') <p class="text-[10px] text-error font-bold" role="alert">{{ $message }}</p> @enderror
                    </div>
                </div>
                <p x-show="errors.comakers" class="text-[10px] text-error font-bold" role="alert" x-text="errors.comakers"></p>
                @error('comakers') <p class="text-[10px] text-error font-bold" role="alert">{{ $message }}</p> @enderror
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

            <button type="submit" class="w-full bg-primary text-white font-[900] py-5 rounded-2xl shadow-xl hover:opacity-90 transition-all text-lg flex items-center justify-center gap-3 disabled:opacity-50" :disabled="loading">
                <template x-if="loading">
                    <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                </template>
                <span x-text="loading ? 'Processing...' : 'Create Loan Request'"></span>
            </button>
        </form>
    </div>
</div>
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
        purpose: 'Educational',
        comakers: ['', ''],
        loading: false,
        isDirty: false,
        errors: {},

        init() {
            // Auto-save: Load draft from localStorage
            const draft = localStorage.getItem('loan_draft');
            if (draft) {
                const data = JSON.parse(draft);
                this.amount = data.amount;
                this.months = data.months;
                this.purpose = data.purpose;
            }

            // Auto-save logic: Watch for changes and save to localStorage
            this.$watch('amount', () => this.saveDraft());
            this.$watch('months', () => this.saveDraft());
            this.$watch('purpose', () => this.saveDraft());
        },

        saveDraft() {
            localStorage.setItem('loan_draft', JSON.stringify({
                amount: this.amount,
                months: this.months,
                purpose: this.purpose
            }));
        },

        validateField(field) {
            this.errors[field] = '';
            if (field === 'shareholder_id' && !this.$el.querySelector('[name=shareholder_id]').value) {
                this.errors.shareholder_id = 'Please select a borrower.';
            }
            if (field === 'purpose' && !this.purpose) {
                this.errors.purpose = 'Loan purpose is required.';
            }
            if (field === 'comakers') {
                if (!this.comakers[0] || !this.comakers[1]) {
                    this.errors.comakers = 'Please select both co-makers.';
                } else if (this.comakers[0] === this.comakers[1]) {
                    this.errors.comakers = 'Co-makers must be different individuals.';
                }
            }
        },

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
