@extends('layouts.dashboard')

@section('title', 'Shareholders')
@section('header_title', 'Shareholders Management')

@section('content')
<div class="space-y-6">
    <div class="flex items-center justify-between bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
        <div>
            <h3 class="text-text-dark text-xl font-bold">Shareholders List</h3>
            <p class="text-text-muted text-sm mt-1">Manage and view all registered shareholders</p>
        </div>
        <a href="{{ route('admin.shareholders.create') }}" class="bg-primary text-white px-4 py-2.5 rounded-xl text-sm font-bold shadow-sm hover:opacity-90 transition-all flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Shareholder
        </a>
    </div>

    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5]">
            <form action="{{ route('admin.shareholders.index') }}" method="GET" class="relative max-w-md">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by name or email..." class="w-full bg-[#F7F8FA] border-none rounded-xl py-2.5 pl-10 pr-4 text-sm focus:ring-1 focus:ring-primary transition-all">
            </form>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[11px] font-bold uppercase tracking-wider">
                        <th class="px-6 py-4">Name</th>
                        <th class="px-6 py-4">Email</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4">Total Shares</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($shareholders as $s)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center text-xs font-bold text-primary">
                                        {{ substr($s->firstname, 0, 1) }}
                                    </div>
                                    <span class="text-sm font-semibold text-text-dark">{{ $s->firstname }} {{ $s->lastname }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4 text-sm text-text-muted">{{ $s->email }}</td>
                            <td class="px-6 py-4">
                                <span class="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase {{ $s->status === 'active' ? 'bg-success/10 text-success' : 'bg-text-muted/10 text-text-muted' }}">
                                    {{ $s->status }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-sm font-bold text-text-dark">₱{{ number_format($s->total_capital, 2) }}</td>
                            <td class="px-6 py-4 text-right">
                                <a href="{{ route('admin.shareholders.show', $s) }}" class="text-primary hover:underline text-xs font-bold">Details</a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-6 py-12 text-center text-text-muted text-sm italic">No shareholders found</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($shareholders->hasPages())
            <div class="px-6 py-4 bg-[#F7F8FA] border-t border-[#F0F1F5]">
                {{ $shareholders->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
