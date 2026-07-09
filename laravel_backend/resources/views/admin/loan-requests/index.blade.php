@extends('layouts.dashboard')

@section('title', 'Loan Requests')
@section('header_title', 'Pending Loan Requests')

@section('content')
<div class="space-y-6">
    <div class="flex items-center justify-between">
        <h3 class="text-text-dark font-bold text-lg">Applications Pending Review</h3>
        <a href="{{ route('admin.loan-requests.create') }}" class="bg-primary text-white px-4 py-2 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all">New Request</a>
    </div>

    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[11px] font-bold uppercase tracking-wider">
                        <th class="px-6 py-4">Borrower</th>
                        <th class="px-6 py-4">Requested Amount</th>
                        <th class="px-6 py-4">Interest Rate</th>
                        <th class="px-6 py-4">Application Date</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($requests as $req)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <span class="text-sm font-semibold text-text-dark">{{ $req->shareholder->full_name ?? 'Unknown' }}</span>
                            </td>
                            <td class="px-6 py-4 text-sm font-bold text-text-dark">₱{{ number_format($req->requested_amount, 2) }}</td>
                            <td class="px-6 py-4 text-sm text-text-muted">{{ $req->interest_rate }}%</td>
                            <td class="px-6 py-4 text-sm text-text-muted">{{ $req->created_at->format('M d, Y') }}</td>
                            <td class="px-6 py-4 text-right">
                                <a href="{{ route('admin.loan-requests.show', $req) }}" class="inline-flex items-center px-3 py-1.5 bg-primary/10 text-primary text-xs font-bold rounded-lg hover:bg-primary hover:text-white transition-all">
                                    Evaluate
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-12 text-center text-text-muted text-sm italic">No pending requests found</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($requests->hasPages())
            <div class="px-6 py-4 bg-[#F7F8FA] border-t border-[#F0F1F5]">
                {{ $requests->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
