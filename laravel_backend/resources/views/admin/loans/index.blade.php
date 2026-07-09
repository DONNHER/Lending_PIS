@extends('layouts.dashboard')

@section('title', 'Loans Management')
@section('header_title', 'Loans Management')

@section('content')
<div class="space-y-6">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Active Loans</h4>
            <p class="text-text-dark text-2xl font-[800] mt-1">{{ $loans->where('status', 'active')->count() }}</p>
        </div>
        <div class="bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Pending Approval</h4>
            <p class="text-warning text-2xl font-[800] mt-1">{{ $loans->where('status', 'pending')->count() }}</p>
        </div>
        <div class="bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Overdue</h4>
            <p class="text-error text-2xl font-[800] mt-1">0</p>
        </div>
    </div>

    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5] flex items-center justify-between">
            <h3 class="text-text-dark font-bold">Current Loans</h3>
            <div class="flex gap-2">
                <a href="{{ route('admin.loans.index') }}" class="px-3 py-1.5 text-xs font-bold rounded-lg {{ !request('status') ? 'bg-primary/10 text-primary' : 'text-text-muted hover:bg-gray-50' }}">All</a>
                <a href="{{ route('admin.loans.index', ['status' => 'active']) }}" class="px-3 py-1.5 text-xs font-bold rounded-lg {{ request('status') == 'active' ? 'bg-primary/10 text-primary' : 'text-text-muted hover:bg-gray-50' }}">Active</a>
                <a href="{{ route('admin.loans.index', ['status' => 'closed']) }}" class="px-3 py-1.5 text-xs font-bold rounded-lg {{ request('status') == 'closed' ? 'bg-primary/10 text-primary' : 'text-text-muted hover:bg-gray-50' }}">Closed</a>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[11px] font-bold uppercase tracking-wider">
                        <th class="px-6 py-4">Borrower</th>
                        <th class="px-6 py-4">Principal</th>
                        <th class="px-6 py-4">Interest Rate</th>
                        <th class="px-6 py-4">Outstanding</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($loans as $loan)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <span class="text-sm font-semibold text-text-dark">{{ $loan->shareholder->full_name ?? 'Unknown' }}</span>
                            </td>
                            <td class="px-6 py-4 text-sm font-bold text-text-dark">₱{{ number_format($loan->principal_amount, 2) }}</td>
                            <td class="px-6 py-4 text-sm text-text-muted">{{ $loan->interest_rate }}%</td>
                            <td class="px-6 py-4 text-sm font-bold text-error">₱{{ number_format($loan->remaining_balance, 2) }}</td>
                            <td class="px-6 py-4">
                                <span class="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase
                                    {{ $loan->status === 'active' ? 'bg-success/10 text-success' : '' }}
                                    {{ $loan->status === 'pending' ? 'bg-warning/10 text-warning' : '' }}
                                    {{ $loan->status === 'closed' ? 'bg-gray-100 text-gray-500' : '' }}
                                ">
                                    {{ $loan->status }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-right">
                                <a href="{{ route('admin.loans.show', $loan) }}" class="text-primary hover:underline text-xs font-bold">View Details</a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-12 text-center text-text-muted text-sm italic">No loans found</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
