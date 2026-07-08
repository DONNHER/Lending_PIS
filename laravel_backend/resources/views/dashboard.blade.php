@extends('layouts.dashboard')

@section('title', 'Dashboard')
@section('header_title', 'Dashboard')

@section('content')
<div class="space-y-8">
    <!-- Header Greeting -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
        <div>
            <h3 class="text-text-dark text-xl font-bold">Good Day, {{ Auth::user()->firstname }}! 👋</h3>
            <p class="text-text-muted text-sm mt-1">{{ date('l, d F Y') }}</p>
        </div>
        <div class="relative max-w-md w-full">
            <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </div>
            <input type="text" placeholder="Search for shareholders..." class="w-full bg-[#F7F8FA] border-none rounded-xl py-2.5 pl-10 pr-4 text-sm focus:ring-1 focus:ring-primary transition-all">
        </div>
    </div>

    <!-- KPI Row -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- Total Shareholders -->
        <div class="bg-white p-5 rounded-2xl border border-[#F0F1F5] shadow-sm group hover:border-primary/30 transition-all">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 01-9-3.47m0-5.037A4.002 4.002 0 0112 4.354" />
                    </svg>
                </div>
                <span class="text-[10px] font-bold text-success bg-success/10 px-2 py-1 rounded-full">+12%</span>
            </div>
            <h4 class="text-text-muted text-xs font-semibold uppercase tracking-wider">Total Shareholders</h4>
            <p class="text-text-dark text-2xl font-[800] mt-1">{{ number_format($stats['total_shareholders']) }}</p>
        </div>

        <!-- Active Loans -->
        <div class="bg-white p-5 rounded-2xl border border-[#F0F1F5] shadow-sm group hover:border-primary/30 transition-all">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-[#6366F1]/10 rounded-xl flex items-center justify-center text-[#6366F1]">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                </div>
                <span class="text-[10px] font-bold text-success bg-success/10 px-2 py-1 rounded-full">+5%</span>
            </div>
            <h4 class="text-text-muted text-xs font-semibold uppercase tracking-wider">Active Loans</h4>
            <p class="text-text-dark text-2xl font-[800] mt-1">{{ number_format($stats['active_loans']) }}</p>
        </div>

        <!-- Total Disbursed -->
        <div class="bg-white p-5 rounded-2xl border border-[#F0F1F5] shadow-sm group hover:border-primary/30 transition-all">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-success/10 rounded-xl flex items-center justify-center text-success">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </div>
            </div>
            <h4 class="text-text-muted text-xs font-semibold uppercase tracking-wider">Total Disbursed</h4>
            <p class="text-text-dark text-2xl font-[800] mt-1">₱{{ number_format($stats['total_disbursed'], 2) }}</p>
        </div>

        <!-- Pending Requests -->
        <div class="bg-white p-5 rounded-2xl border border-[#F0F1F5] shadow-sm group hover:border-primary/30 transition-all">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-[#F59E0B]/10 rounded-xl flex items-center justify-center text-[#F59E0B]">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </div>
            </div>
            <h4 class="text-text-muted text-xs font-semibold uppercase tracking-wider">Pending Requests</h4>
            <p class="text-text-dark text-2xl font-[800] mt-1">0</p>
        </div>
    </div>

    <!-- Chart Section (Placeholder for Bar Chart) -->
    <div class="bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
        <div class="flex items-center justify-between mb-8">
            <div>
                <h4 class="text-text-dark font-bold text-base">Revenue & Collection Trend</h4>
                <p class="text-text-muted text-xs mt-0.5">Performance over time</p>
            </div>
            <div class="flex bg-[#F3F4F6] p-1 rounded-lg">
                <button class="px-4 py-1.5 text-[11px] font-bold rounded-md bg-white shadow-sm text-primary">Week</button>
                <button class="px-4 py-1.5 text-[11px] font-bold rounded-md text-text-muted hover:text-text-dark transition-colors">Month</button>
                <button class="px-4 py-1.5 text-[11px] font-bold rounded-md text-text-muted hover:text-text-dark transition-colors">Year</button>
            </div>
        </div>
        <div class="h-64 flex items-end gap-3 px-4">
            <!-- Simulated Bar Chart -->
            @foreach([40, 70, 45, 90, 65, 80, 55] as $height)
                <div class="flex-1 bg-primary/20 hover:bg-primary rounded-t-lg transition-all relative group cursor-pointer" style="height: {{ $height }}%">
                    <div class="absolute -top-10 left-1/2 -translate-x-1/2 bg-text-dark text-white text-[10px] py-1 px-2 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        ₱{{ number_format($height * 1000) }}
                    </div>
                </div>
            @endforeach
        </div>
        <div class="flex justify-between mt-4 px-4">
            @foreach(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] as $day)
                <span class="text-[10px] font-bold text-text-muted w-full text-center">{{ $day }}</span>
            @endforeach
        </div>
    </div>

    <!-- Recent Transactions Table -->
    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5] flex items-center justify-between">
            <h4 class="text-text-dark font-bold text-base">Recent Transactions</h4>
            <a href="#" class="text-primary text-xs font-bold hover:underline">View All</a>
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
                    @forelse($stats['recent_transactions'] as $tx)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4 text-xs font-bold text-text-dark">#{{ substr($tx->id, 0, 8) }}</td>
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-2.5">
                                    <div class="w-7 h-7 bg-primary/10 rounded-full flex items-center justify-center text-[10px] font-bold text-primary">
                                        {{ substr($tx->shareholder->full_name ?? 'U', 0, 1) }}
                                    </div>
                                    <span class="text-xs font-semibold text-text-dark">{{ $tx->shareholder->full_name ?? 'Unknown' }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-[11px] font-medium text-text-muted">{{ $tx->type }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-xs font-bold {{ $tx->amount < 0 ? 'text-error' : 'text-success' }}">
                                    {{ $tx->amount < 0 ? '-' : '+' }}₱{{ number_format(abs($tx->amount), 2) }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-[11px] text-text-muted">
                                {{ $tx->created_at->format('M d, Y h:i A') }}
                            </td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-1 rounded-full text-[9px] font-bold uppercase {{ $tx->status === 'completed' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning' }}">
                                    {{ $tx->status }}
                                </span>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-12 text-center text-text-muted text-sm italic">No recent transactions found</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
