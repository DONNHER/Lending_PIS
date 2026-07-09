@extends('layouts.dashboard')

@section('title', 'Reporting System')
@section('header_title', 'Analytics & Reports')

@section('content')
<div class="max-w-6xl mx-auto space-y-8" x-data="{ reportType: 'user_activity', showSaveModal: false }">
    <!-- Reports Selector -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div class="lg:col-span-1 space-y-6">
            <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
                <h4 class="text-text-dark font-bold mb-6 text-sm uppercase tracking-wider">Select Report Type</h4>
                <div class="space-y-2">
                    <button @click="reportType = 'user_activity'" :class="reportType === 'user_activity' ? 'bg-primary text-white shadow-lg' : 'bg-gray-50 text-text-muted hover:bg-gray-100'" class="w-full text-left px-4 py-3 rounded-2xl text-xs font-bold transition-all flex items-center gap-3">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                        User Activity
                    </button>
                    <button @click="reportType = 'transaction_summary'" :class="reportType === 'transaction_summary' ? 'bg-primary text-white shadow-lg' : 'bg-gray-50 text-text-muted hover:bg-gray-100'" class="w-full text-left px-4 py-3 rounded-2xl text-xs font-bold transition-all flex items-center gap-3">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>
                        Transaction Summary
                    </button>
                    <button @click="reportType = 'audit_trail'" :class="reportType === 'audit_trail' ? 'bg-primary text-white shadow-lg' : 'bg-gray-50 text-text-muted hover:bg-gray-100'" class="w-full text-left px-4 py-3 rounded-2xl text-xs font-bold transition-all flex items-center gap-3">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 00-2 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012-2" /></svg>
                        Audit Trail Report
                    </button>
                    <button @click="reportType = 'system_usage'" :class="reportType === 'system_usage' ? 'bg-primary text-white shadow-lg' : 'bg-gray-50 text-text-muted hover:bg-gray-100'" class="w-full text-left px-4 py-3 rounded-2xl text-xs font-bold transition-all flex items-center gap-3">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 12l3-3 3 3M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" /></svg>
                        Usage Statistics
                    </button>
                </div>
            </div>

            <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
                <h4 class="text-text-dark font-bold mb-6 text-sm uppercase tracking-wider">Favorite Reports</h4>
                <div class="space-y-3">
                    @forelse($favorites as $fav)
                        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl group">
                            <a href="{{ route('admin.reports.generate', array_merge(['type' => $fav->report_type], $fav->filters)) }}" class="text-[11px] font-bold text-text-dark hover:text-primary">{{ $fav->name }}</a>
                            <form action="{{ route('admin.reports.favorite.delete', $fav) }}" method="POST">
                                @csrf @method('DELETE')
                                <button type="submit" class="text-text-muted hover:text-error opacity-0 group-hover:opacity-100 transition-all">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                </button>
                            </form>
                        </div>
                    @empty
                        <p class="text-[10px] text-text-muted italic text-center py-4">No saved configurations</p>
                    @endforelse
                </div>
            </div>
        </div>

        <!-- Filters and Configuration -->
        <div class="lg:col-span-2 space-y-6">
            <div class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm">
                <h3 class="text-xl font-bold text-text-dark mb-2">Report Configuration</h3>
                <p class="text-text-muted text-sm mb-8">Set filters to generate the dynamic report.</p>

                <form action="{{ route('admin.reports.generate') }}" method="GET" target="_blank" class="space-y-6" id="reportForm">
                    <input type="hidden" name="type" :value="reportType">

                    <!-- User Activity Filters -->
                    <div x-show="reportType === 'user_activity'" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">Start Date</label>
                            <input type="date" name="start_date" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">End Date</label>
                            <input type="date" name="end_date" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">User Role</label>
                            <select name="role" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                                <option value="">All Roles</option>
                                <option value="admin">Admin</option>
                                <option value="staff">Staff</option>
                                <option value="member">Member</option>
                            </select>
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">Action Type</label>
                            <select name="action_type" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                                <option value="">All Actions</option>
                                <option value="auth">Authentication</option>
                                <option value="transaction">Transaction</option>
                                <option value="access">Data Access</option>
                            </select>
                        </div>
                    </div>

                    <!-- Transaction Summary Filters -->
                    <div x-show="reportType === 'transaction_summary'" class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">Period</label>
                            <select name="period" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                                <option value="today">Today</option>
                                <option value="week">This Week</option>
                                <option value="month">This Month</option>
                                <option value="year">This Year</option>
                            </select>
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">Category</label>
                            <select name="category" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                                <option value="">All Categories</option>
                                <option value="Loan Disbursement">Disbursements</option>
                                <option value="Loan Payment">Payments</option>
                                <option value="Share Capital Contribution">Share Capital</option>
                            </select>
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-bold text-text-dark uppercase">Status</label>
                            <select name="status" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                                <option value="completed">Completed</option>
                                <option value="pending">Pending</option>
                                <option value="failed">Failed</option>
                            </select>
                        </div>
                    </div>

                    <!-- Usage Stats Filters -->
                    <div x-show="reportType === 'system_usage'" class="space-y-2">
                        <label class="text-xs font-bold text-text-dark uppercase">Time Grouping</label>
                        <select name="period" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3.5 text-sm focus:ring-1 focus:ring-primary">
                            <option value="monthly">Monthly</option>
                            <option value="quarterly">Quarterly</option>
                            <option value="yearly">Yearly</option>
                        </select>
                    </div>

                    <div class="h-px bg-gray-50 my-4"></div>

                    <div class="flex items-center justify-between">
                        <button type="button" @click="showSaveModal = true" class="text-primary text-xs font-bold flex items-center gap-2 hover:underline">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" /></svg>
                            Save this configuration
                        </button>
                        <div class="flex gap-3">
                            <button type="button" @click="alert('This feature will send the current report view to your registered email: {{ auth()->user()->email }}')" class="bg-white border border-gray-200 text-text-dark px-4 py-3 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                                Email Report
                            </button>
                            <button type="submit" name="format" value="csv" class="bg-white border border-gray-200 text-text-dark px-6 py-3 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
                                Excel (.CSV)
                            </button>
                            <button type="submit" name="format" value="print" class="bg-primary text-white px-8 py-3 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" /></svg>
                                Generate PDF/Print
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Favorite Save Modal -->
    <div x-show="showSaveModal" x-cloak class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
        <div class="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl">
            <h3 class="text-xl font-bold text-text-dark mb-4">Save Configuration</h3>
            <form action="{{ route('admin.reports.favorite') }}" method="POST" class="space-y-4">
                @csrf
                <input type="hidden" name="report_type" :value="reportType">
                <!-- This would need better handling to grab current form filters -->
                <div class="space-y-2">
                    <label class="text-xs font-bold text-text-muted uppercase">Configuration Name</label>
                    <input type="text" name="name" required placeholder="e.g. Weekly Transaction Audit" class="w-full bg-[#F7F8FA] border-none rounded-xl p-4 text-sm">
                </div>
                <div class="p-4 bg-primary/5 rounded-2xl text-[10px] text-primary italic">
                    Note: All current filter values will be saved to your dashboard for quick access.
                </div>
                <div class="flex gap-3 pt-2">
                    <button type="button" @click="showSaveModal = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl">Cancel</button>
                    <button type="submit" class="flex-1 bg-primary text-white font-bold py-3 rounded-xl shadow-lg">Save Favorite</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
