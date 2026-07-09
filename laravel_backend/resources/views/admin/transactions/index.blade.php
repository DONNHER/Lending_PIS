@extends('layouts.dashboard')

@section('title', 'Transactions')
@section('header_title', 'Transaction History')

@section('content')
<div class="space-y-6" x-data="advancedTable()">
    <!-- Top Action Bar -->
    <div class="flex flex-col lg:flex-row lg:items-center justify-between bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm gap-4">
        <h3 class="text-text-dark text-xl font-bold">Financial Ledger</h3>

        <div class="flex flex-wrap gap-2">
            <button @click="showFilters = !showFilters" :class="showFilters ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-text-dark'" class="px-4 py-2.5 rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" /></svg>
                Filters
            </button>

            <div class="relative" x-data="{ open: false }">
                <button @click="open = !open" class="bg-white border border-gray-200 text-text-dark px-4 py-2.5 rounded-xl text-[10px] font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
                    Export View
                </button>
                <div x-show="open" @click.away="open = false" x-cloak class="absolute right-0 mt-2 w-40 bg-white border border-gray-100 shadow-xl rounded-xl py-2 z-10">
                    <a href="{{ request()->fullUrlWithQuery(['export' => 'csv', 'format' => 'csv']) }}" class="flex items-center gap-2 px-4 py-2 text-xs font-bold text-text-dark hover:bg-gray-50">CSV Spreadsheet</a>
                    <a href="{{ request()->fullUrlWithQuery(['export' => 'pdf', 'format' => 'pdf']) }}" class="flex items-center gap-2 px-4 py-2 text-xs font-bold text-text-dark hover:bg-gray-50">PDF Statement</a>
                </div>
            </div>
        </div>
    </div>

    <!-- Filters Drawer -->
    <div x-show="showFilters" x-collapse x-cloak class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm">
        <form action="{{ route('admin.transactions.index') }}" method="GET" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Search Description</label>
                    <input type="text" name="search" value="{{ request('search') }}" placeholder="Details..." class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Transaction Type</label>
                    <select name="type" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        <option value="">All Categories</option>
                        <option value="Loan Payment" {{ request('type') == 'Loan Payment' ? 'selected' : '' }}>Loan Payment</option>
                        <option value="Share Capital Contribution" {{ request('type') == 'Share Capital Contribution' ? 'selected' : '' }}>Share Capital</option>
                    </select>
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Status</label>
                    <select name="status" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        <option value="">All Statuses</option>
                        <option value="completed" {{ request('status') == 'completed' ? 'selected' : '' }}>Completed</option>
                        <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>Pending</option>
                    </select>
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Rows</label>
                    <select name="per_page" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        @foreach([15, 30, 50, 100] as $count)
                            <option value="{{ $count }}" {{ request('per_page') == $count ? 'selected' : '' }}>{{ $count }} rows</option>
                        @endforeach
                    </select>
                </div>
            </div>
            <div class="flex justify-end pt-4 border-t border-gray-50">
                <button type="submit" class="bg-primary text-white px-8 py-2.5 rounded-xl text-xs font-bold shadow-lg">Filter Ledger</button>
            </div>
        </form>
    </div>

    <div class="bg-white rounded-[32px] border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[10px] font-black uppercase tracking-widest">
                        <th class="px-6 py-5 cursor-pointer" @click="sort('id')">TX ID</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('shareholder_id')">Shareholder</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('type')">Classification</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('amount')">Volume</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('date')">Timestamp</th>
                        <th class="px-6 py-5">Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($transactions as $tx)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4 text-[10px] font-bold text-text-dark">#{{ substr($tx->id, 0, 8) }}</td>
                            <td class="px-6 py-4">
                                <p class="text-xs font-bold text-text-dark">{{ $tx->shareholder->full_name ?? 'System' }}</p>
                                <p class="text-[9px] text-text-muted uppercase tracking-tighter">{{ $tx->method }}</p>
                            </td>
                            <td class="px-6 py-4 text-[10px] font-medium text-text-muted uppercase">{{ $tx->type }}</td>
                            <td class="px-6 py-4">
                                <span class="text-xs font-black {{ $tx->amount < 0 ? 'text-error' : 'text-success' }}">
                                    {{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-[10px] text-text-muted">{{ $tx->date->format('M d, Y h:i A') }}</td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-1 rounded-full text-[9px] font-black uppercase {{ $tx->status === 'completed' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning' }}">
                                    {{ $tx->status }}
                                </span>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="px-6 py-20 text-center text-text-muted italic">No financial records matching filters.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($transactions->hasPages())
            <div class="px-8 py-6 bg-[#F7F8FA] border-t border-[#F0F1F5]">{{ $transactions->links() }}</div>
        @endif
    </div>
</div>
@endsection

@push('scripts')
<script>
function advancedTable() {
    return {
        showFilters: false,
        sortBy: '{{ request('sort_by', 'date') }}',
        sortOrder: '{{ request('sort_order', 'desc') }}',
        sort(column) {
            this.sortOrder = (this.sortBy === column && this.sortOrder === 'asc') ? 'desc' : 'asc';
            this.sortBy = column;
            const url = new URL(window.location.href);
            url.searchParams.set('sort_by', this.sortBy);
            url.searchParams.set('sort_order', this.sortOrder);
            window.location.href = url.toString();
        }
    }
}
</script>
@endpush
