@extends('layouts.dashboard')

@section('title', 'Audit Trail')
@section('header_title', 'System Activity Logs')

@section('content')
<div class="space-y-6">
    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5] flex items-center justify-between">
            <h3 class="text-text-dark font-bold">Recent Activities</h3>
            <div class="flex gap-4">
                <select class="bg-[#F7F8FA] border-none rounded-xl py-2 px-4 text-xs font-bold text-text-dark focus:ring-1 focus:ring-primary">
                    <option value="">All Types</option>
                    <option value="auth">Authentication</option>
                    <option value="transaction">Financial</option>
                    <option value="access">Access</option>
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
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-7 h-7 bg-gray-100 rounded-lg flex items-center justify-center text-[10px] font-bold text-gray-500">
                                        {{ substr($log->user->firstname ?? 'S', 0, 1) }}
                                    </div>
                                    <span class="text-xs font-semibold text-text-dark">{{ $log->user->full_name ?? 'System' }}</span>
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
