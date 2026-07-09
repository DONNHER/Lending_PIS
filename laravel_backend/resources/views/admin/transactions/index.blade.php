@extends('layouts.dashboard')

@section('title', 'Transactions')
@section('header_title', 'Transaction History')

@section('content')
<div class="space-y-6">
    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5] flex items-center justify-between">
            <h3 class="text-text-dark font-bold">All Transactions</h3>
            <div class="flex gap-4">
                <select class="bg-[#F7F8FA] border-none rounded-xl py-2 px-4 text-xs font-bold text-text-dark focus:ring-1 focus:ring-primary">
                    <option>All Types</option>
                    <option>Loan Payment</option>
                    <option>Share Capital</option>
                    <option>Withdrawal</option>
                </select>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[11px] font-bold uppercase tracking-wider">
                        <th class="px-6 py-4">Transaction ID</th>
                        <th class="px-6 py-4">Shareholder</th>
                        <th class="px-6 py-4">Type</th>
                        <th class="px-6 py-4">Amount</th>
                        <th class="px-6 py-4">Date</th>
                        <th class="px-6 py-4">Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($transactions as $tx)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4 text-xs font-bold text-text-dark">#{{ substr($tx->id, 0, 8) }}</td>
                            <td class="px-6 py-4">
                                <span class="text-xs font-semibold text-text-dark">{{ $tx->shareholder->full_name ?? 'Unknown' }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-[11px] font-medium text-text-muted uppercase tracking-tighter">{{ $tx->type }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-xs font-bold {{ $tx->amount < 0 ? 'text-error' : 'text-success' }}">
                                    {{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-[11px] text-text-muted">
                                {{ $tx->date->format('M d, Y h:i A') }}
                            </td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-1 rounded-full text-[9px] font-bold uppercase {{ $tx->status === 'completed' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning' }}">
                                    {{ $tx->status }}
                                </span>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-12 text-center text-text-muted text-sm italic">No transactions found</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($transactions->hasPages())
            <div class="px-6 py-4 bg-[#F7F8FA] border-t border-[#F0F1F5]">
                {{ $transactions->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
