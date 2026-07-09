@extends('layouts.dashboard')

@section('title', 'Audit Trail')
@section('header_title', 'System Activity Logs')

@section('content')
<div class="space-y-6">
    <div class="flex items-center justify-between bg-white p-6 rounded-2xl border border-[#F0F1F5] shadow-sm">
        <div>
            <h3 class="text-text-dark text-xl font-bold">Audit Records</h3>
            <p class="text-text-muted text-sm mt-1">Review system activities and transactions</p>
        </div>
        <a href="{{ request()->fullUrlWithQuery(['export' => 1]) }}" class="bg-primary text-white px-4 py-2.5 rounded-xl text-sm font-bold shadow-sm hover:opacity-90 transition-all flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4-4m0 0L8 8m4-4v12" /></svg>
            Export to CSV
        </a>
    </div>

    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5] flex flex-col md:flex-row gap-4 justify-between">
            <form action="{{ route('admin.activity-logs.index') }}" method="GET" class="relative max-w-md w-full">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                </div>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search action, description or IP..." class="w-full bg-[#F7F8FA] border-none rounded-xl py-2.5 pl-10 pr-4 text-sm focus:ring-1 focus:ring-primary">
            </form>
            <div class="flex gap-2">
                <select name="type" onchange="window.location.href='{{ route('admin.activity-logs.index') }}?type=' + this.value" class="bg-[#F7F8FA] border-none rounded-xl py-2 px-4 text-xs font-bold text-text-dark focus:ring-1 focus:ring-primary">
                    <option value="">All Types</option>
                    <option value="auth" {{ request('type') == 'auth' ? 'selected' : '' }}>Authentication</option>
                    <option value="transaction" {{ request('type') == 'transaction' ? 'selected' : '' }}>Financial</option>
                    <option value="error" {{ request('type') == 'error' ? 'selected' : '' }}>System Error</option>
                    <option value="access" {{ request('type') == 'access' ? 'selected' : '' }}>Access</option>
                </select>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[11px] font-bold uppercase tracking-wider">
                        <th class="px-6 py-4">User</th>
                        <th class="px-6 py-4">Action</th>
                        <th class="px-6 py-4">Type</th>
                        <th class="px-6 py-4">IP Address</th>
                        <th class="px-6 py-4">Timestamp</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($logs as $log)
                        <tr class="hover:bg-gray-50/50 transition-colors {{ $log->is_suspicious ? 'bg-error/5' : '' }}">
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-7 h-7 bg-gray-100 rounded-lg flex items-center justify-center text-[10px] font-bold text-gray-500">
                                        {{ substr($log->user->firstname ?? 'S', 0, 1) }}
                                    </div>
                                    <div>
                                        <p class="text-xs font-semibold text-text-dark">{{ $log->user->full_name ?? 'System' }}</p>
                                        @if($log->is_suspicious)
                                            <span class="text-[8px] font-black text-error uppercase tracking-tighter bg-error/10 px-1 rounded flex items-center gap-1 w-fit mt-0.5">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-2 w-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                                                Suspicious
                                            </span>
                                        @endif
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-xs font-medium text-text-dark">{{ $log->action }}</span>
                                <p class="text-[10px] text-text-muted mt-0.5 truncate max-w-xs">{{ $log->description }}</p>
                            </td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase
                                    {{ $log->log_type === 'auth' ? 'bg-blue-100 text-blue-600' : '' }}
                                    {{ $log->log_type === 'transaction' ? 'bg-green-100 text-green-600' : '' }}
                                    {{ $log->log_type === 'error' ? 'bg-red-100 text-red-600' : '' }}
                                    {{ $log->log_type === 'access' ? 'bg-gray-100 text-gray-600' : '' }}
                                ">
                                    {{ $log->log_type }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-[11px] text-text-muted font-mono">{{ $log->ip_address }}</td>
                            <td class="px-6 py-4 text-[11px] text-text-muted">{{ $log->created_at->format('M d, Y h:i A') }}</td>
                            <td class="px-6 py-4 text-right">
                                <a href="{{ route('admin.activity-logs.show', $log) }}" class="text-primary hover:underline text-[11px] font-bold">Details</a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-12 text-center text-text-muted text-sm italic">No activity logs found</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($logs->hasPages())
            <div class="px-6 py-4 bg-[#F7F8FA] border-t border-[#F0F1F5]">
                {{ $logs->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
