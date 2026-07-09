@extends('layouts.dashboard')

@section('title', 'Admin Dashboard')
@section('header_title', 'Dashboard Overview')

@section('breadcrumbs')
    <x-breadcrumb :items="[]" />
@endsection

@section('content')
<div class="space-y-8" x-data="dashboard()">
    <!-- System Alerts -->
    @if($stats['system_health']['storage_usage'] >= 85)
        <div class="p-4 bg-error/10 border border-error/20 rounded-2xl flex items-center justify-between">
            <div class="flex items-center gap-3 text-error">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.268 17c-.77 1.333.192 3 1.732 3z" /></svg>
                <div>
                    <p class="text-sm font-bold">Critical Storage Warning</p>
                    <p class="text-xs opacity-80">Server storage is at {{ $stats['system_health']['storage_usage'] }}%. Please consider cleaning up old backups or logs.</p>
                </div>
            </div>
            <a href="{{ route('admin.backups.index') }}" class="bg-error text-white text-[10px] font-bold px-4 py-2 rounded-xl">Manage Backups</a>
        </div>
    @endif

    <!-- Loading State for Stats -->
    <div x-show="loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <x-skeleton type="card" count="1" />
        <x-skeleton type="card" count="1" />
        <x-skeleton type="card" count="1" />
        <x-skeleton type="card" count="1" />
    </div>

    <!-- Top Row: Statistics Widgets -->
    <div x-show="!loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <!-- User Statistics -->
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                </div>
                <span class="text-[10px] font-bold text-success bg-success/10 px-2 py-1 rounded-lg">Active Now: {{ $stats['active_now'] }}</span>
            </div>
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Total Users</h4>
            <p class="text-2xl font-black text-text-dark mt-1">{{ number_format($stats['total_users']) }}</p>
        </div>

        <!-- Loan Statistics -->
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-secondary/10 rounded-xl flex items-center justify-center text-secondary">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                </div>
            </div>
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Active Loans</h4>
            <p class="text-2xl font-black text-text-dark mt-1">{{ $stats['active_loans'] }}</p>
        </div>

        <!-- Financial Overview -->
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-success/10 rounded-xl flex items-center justify-center text-success">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>
                </div>
            </div>
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Total Disbursed</h4>
            <p class="text-2xl font-black text-text-dark mt-1">₱{{ number_format($stats['total_disbursed'], 0) }}</p>
        </div>

        <!-- Shareholder Count -->
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center text-primary">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 01-9-3.47m0-5.037A4.002 4.002 0 0112 4.354" /></svg>
                </div>
            </div>
            <h4 class="text-text-muted text-xs font-bold uppercase tracking-wider">Shareholders</h4>
            <p class="text-2xl font-black text-text-dark mt-1">{{ $stats['total_shareholders'] }}</p>
        </div>
    </div>

    <!-- Second Row: Charts & Data Visualization -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Transaction Activity Graph -->
        <div class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-8">
                <div>
                    <h4 class="text-text-dark font-bold text-lg">Transaction Overview</h4>
                    <p class="text-text-muted text-xs mt-1">Daily/Weekly/Monthly activity</p>
                </div>
                <div class="flex gap-2 bg-gray-50 p-1 rounded-xl">
                    <button @click="changeRange('week')" :class="range === 'week' ? 'bg-white shadow-sm text-primary' : 'text-text-muted'" class="px-3 py-1.5 text-[10px] font-bold rounded-lg transition-all">WEEK</button>
                    <button @click="changeRange('month')" :class="range === 'month' ? 'bg-white shadow-sm text-primary' : 'text-text-muted'" class="px-3 py-1.5 text-[10px] font-bold rounded-lg transition-all">MONTH</button>
                </div>
            </div>
            <div class="h-64 relative">
                <canvas id="transactionChart"></canvas>
            </div>
        </div>

        <!-- User Registration Chart -->
        <div class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-8">
                <div>
                    <h4 class="text-text-dark font-bold text-lg">User Growth</h4>
                    <p class="text-text-muted text-xs mt-1">New registrations trend</p>
                </div>
            </div>
            <div class="h-64 relative">
                <canvas id="userGrowthChart"></canvas>
            </div>
        </div>
    </div>

    <!-- Third Row: System Health, Recent Activity & Performance -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Recent Activities -->
        <div class="lg:col-span-2 bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
            <div class="p-6 border-b border-[#F0F1F5] flex items-center justify-between">
                <h4 class="text-text-dark font-bold">Recent System Activities</h4>
                <a href="{{ route('admin.activity-logs.index') }}" class="text-primary text-xs font-bold">View Audit Trail</a>
            </div>
            <div class="divide-y divide-[#F0F1F5]">
                @foreach($stats['recent_activities'] as $log)
                    <div class="p-4 flex items-center gap-4 hover:bg-gray-50 transition-colors">
                        <div class="w-2 h-2 rounded-full {{ $log->log_type === 'error' ? 'bg-error' : ($log->log_type === 'transaction' ? 'bg-success' : 'bg-primary') }}"></div>
                        <div class="flex-1">
                            <p class="text-sm font-bold text-text-dark">{{ $log->action }}</p>
                            <p class="text-[10px] text-text-muted">{{ $log->description }}</p>
                        </div>
                        <div class="text-right">
                            <p class="text-[10px] font-bold text-text-dark">{{ $log->user->firstname ?? 'System' }}</p>
                            <p class="text-[9px] text-text-muted">{{ $log->created_at->diffForHumans() }}</p>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>

        <!-- System Health & Performance -->
        <div class="space-y-6">
            <!-- System Health -->
            <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
                <h4 class="text-text-dark font-bold mb-6">System Health</h4>
                <div class="space-y-4">
                    <div class="flex items-center justify-between">
                        <span class="text-xs text-text-muted font-medium">Server Uptime</span>
                        <span class="text-xs font-bold text-success">{{ $stats['system_health']['uptime'] }}</span>
                    </div>
                    <div class="flex items-center justify-between">
                        <span class="text-xs text-text-muted font-medium">Database Size</span>
                        <span class="text-xs font-bold text-text-dark">{{ $stats['system_health']['db_size'] }}</span>
                    </div>
                    <div>
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-xs text-text-muted font-medium">Storage Usage</span>
                            <span class="text-xs font-bold text-text-dark">{{ $stats['system_health']['storage_usage'] }}%</span>
                        </div>
                        <div class="w-full bg-gray-100 rounded-full h-1.5">
                            <div class="bg-primary h-1.5 rounded-full" style="width: {{ $stats['system_health']['storage_usage'] }}%"></div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Performance Metrics -->
            <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
                <h4 class="text-text-dark font-bold mb-6">Performance</h4>
                <div class="grid grid-cols-2 gap-4">
                    <div class="p-4 bg-gray-50 rounded-2xl">
                        <p class="text-[10px] font-bold text-text-muted uppercase mb-1">Response Time</p>
                        <p class="text-lg font-black text-text-dark">{{ $stats['performance']['avg_response_time'] }}</p>
                    </div>
                    <div class="p-4 bg-gray-50 rounded-2xl">
                        <p class="text-[10px] font-bold text-text-muted uppercase mb-1">Error Rate</p>
                        <p class="text-lg font-black {{ $stats['performance']['error_rate'] > 5 ? 'text-error' : 'text-success' }}">
                            {{ $stats['performance']['error_rate'] }}%
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
        <h4 class="text-text-dark font-bold mb-6">Quick Actions</h4>
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <a href="{{ route('admin.shareholders.create') }}" class="flex flex-col items-center gap-3 p-4 bg-primary/5 rounded-2xl group hover:bg-primary transition-all">
                <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary group-hover:bg-white/20 group-hover:text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" /></svg>
                </div>
                <span class="text-[10px] font-black uppercase text-primary group-hover:text-white text-center">New Shareholder</span>
            </a>
            <a href="{{ route('admin.loan-requests.create') }}" class="flex flex-col items-center gap-3 p-4 bg-secondary/5 rounded-2xl group hover:bg-secondary transition-all">
                <div class="w-10 h-10 rounded-full bg-secondary/10 flex items-center justify-center text-secondary group-hover:bg-white/20 group-hover:text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                </div>
                <span class="text-[10px] font-black uppercase text-secondary group-hover:text-white text-center">Create Loan</span>
            </a>
            <a href="{{ route('admin.transactions.index') }}" class="flex flex-col items-center gap-3 p-4 bg-success/5 rounded-2xl group hover:bg-success transition-all">
                <div class="w-10 h-10 rounded-full bg-success/10 flex items-center justify-center text-success group-hover:bg-white/20 group-hover:text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                </div>
                <span class="text-[10px] font-black uppercase text-success group-hover:text-white text-center">Ledger</span>
            </a>
            <a href="{{ route('admin.backups.index') }}" class="flex flex-col items-center gap-3 p-4 bg-gray-50 rounded-2xl group hover:bg-text-dark transition-all">
                <div class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center text-gray-400 group-hover:bg-white/20 group-hover:text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" /></svg>
                </div>
                <span class="text-[10px] font-black uppercase text-text-muted group-hover:text-white text-center">Backup</span>
            </a>
            <a href="{{ route('admin.settings.index') }}" class="flex flex-col items-center gap-3 p-4 bg-gray-50 rounded-2xl group hover:bg-text-dark transition-all">
                <div class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center text-gray-400 group-hover:bg-white/20 group-hover:text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /></svg>
                </div>
                <span class="text-[10px] font-black uppercase text-text-muted group-hover:text-white text-center">Settings</span>
            </a>
            <a href="{{ route('admin.activity-logs.index') }}" class="flex flex-col items-center gap-3 p-4 bg-gray-50 rounded-2xl group hover:bg-text-dark transition-all">
                <div class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center text-gray-400 group-hover:bg-white/20 group-hover:text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 00-2 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012-2" /></svg>
                </div>
                <span class="text-[10px] font-black uppercase text-text-muted group-hover:text-white text-center">Audit</span>
            </a>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
function dashboard() {
    return {
        range: 'week',
        loading: true,
        transactionChart: null,
        userGrowthChart: null,

        init() {
            this.fetchStats();
        },

        async fetchStats() {
            this.loading = true;
            try {
                const response = await fetch(`/api/dashboard/stats?range=${this.range}`, {
                    headers: {
                        'Accept': 'application/json',
                        'Authorization': 'Bearer ' + '{{ Auth::user()->createToken("web-dashboard")->plainTextToken }}' // Note: In a real app, use existing session/cookie
                    }
                });
                const data = await response.json();
                if (data.success) {
                    this.updateCharts(data);
                }
            } catch (error) {
                console.error('Failed to fetch dashboard stats:', error);
            } finally {
                this.loading = false;
            }
        },

        changeRange(range) {
            this.range = range;
            this.fetchStats();
        },

        updateCharts(data) {
            this.renderTransactionChart(data.transaction_stats);
            this.renderUserGrowthChart(data.user_stats);
        },

        renderTransactionChart(stats) {
            const ctx = document.getElementById('transactionChart').getContext('2d');
            if (this.transactionChart) this.transactionChart.destroy();

            this.transactionChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: stats.activity_chart.labels,
                    datasets: [{
                        label: 'Transactions',
                        data: stats.activity_chart.datasets[0].data,
                        borderColor: '#FF6F00',
                        backgroundColor: 'rgba(255, 111, 0, 0.1)',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 3,
                        pointRadius: 4,
                        pointBackgroundColor: '#fff',
                        pointBorderColor: '#FF6F00',
                        pointBorderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { beginAtZero: true, grid: { display: false }, ticks: { font: { size: 10 } } },
                        x: { grid: { display: false }, ticks: { font: { size: 10 } } }
                    }
                }
            });
        },

        renderUserGrowthChart(stats) {
            const ctx = document.getElementById('userGrowthChart').getContext('2d');
            if (this.userGrowthChart) this.userGrowthChart.destroy();

            this.userGrowthChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: stats.trend.labels,
                    datasets: [{
                        label: 'New Registrations',
                        data: stats.trend.data,
                        backgroundColor: '#FFA726',
                        borderRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { beginAtZero: true, grid: { display: false }, ticks: { font: { size: 10 } } },
                        x: { grid: { display: false }, ticks: { font: { size: 10 } } }
                    }
                }
            });
        }
    }
}
</script>
@endpush
