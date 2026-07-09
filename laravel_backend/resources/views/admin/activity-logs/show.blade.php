@extends('layouts.dashboard')

@section('title', 'Log Details')
@section('header_title', 'Activity Details')

@section('content')
<div class="max-w-4xl mx-auto space-y-8">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-gray-100 flex items-center justify-between">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 bg-gray-100 rounded-2xl flex items-center justify-center text-gray-400">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                </div>
                <div>
                    <h3 class="text-text-dark font-bold text-lg">{{ $activityLog->action }}</h3>
                    <p class="text-text-muted text-sm">{{ $activityLog->created_at->format('F d, Y \a\t h:i A') }}</p>
                </div>
            </div>
            <span class="px-3 py-1 bg-gray-100 text-gray-600 text-[10px] font-bold rounded-full uppercase tracking-tighter">Log ID: #{{ substr($activityLog->id, 0, 8) }}</span>
        </div>

        <div class="p-8 space-y-8">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div>
                    <h4 class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-4">Event Context</h4>
                    <div class="space-y-4">
                        <div class="flex justify-between">
                            <span class="text-sm text-text-muted">Initiated By</span>
                            <span class="text-sm font-bold text-text-dark">{{ $activityLog->user->full_name ?? 'System' }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-sm text-text-muted">Log Type</span>
                            <span class="text-sm font-bold text-primary uppercase">{{ $activityLog->log_type }}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-sm text-text-muted">IP Address</span>
                            <span class="text-sm font-mono text-text-dark">{{ $activityLog->ip_address }}</span>
                        </div>
                    </div>
                </div>
                <div>
                    <h4 class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-4">Device Info</h4>
                    <p class="text-xs text-text-dark font-medium leading-relaxed bg-gray-50 p-4 rounded-xl">
                        {{ $activityLog->device_info }}
                    </p>
                </div>
            </div>

            <div>
                <h4 class="text-[10px] font-bold text-text-muted uppercase tracking-widest mb-4">Description</h4>
                <p class="text-sm text-text-dark bg-[#F7F8FA] p-6 rounded-2xl border border-gray-100">
                    {{ $activityLog->description }}
                </p>
            </div>

            @if($activityLog->old_values || $activityLog->new_values)
                <div class="space-y-6">
                    <h4 class="text-[10px] font-bold text-text-muted uppercase tracking-widest">Data Changes</h4>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="bg-red-50/50 p-6 rounded-2xl border border-red-100">
                            <p class="text-[10px] font-bold text-red-600 uppercase mb-4 tracking-tighter">Previous State</p>
                            <pre class="text-[11px] text-red-800 whitespace-pre-wrap">{{ json_encode($activityLog->old_values, JSON_PRETTY_PRINT) }}</pre>
                        </div>
                        <div class="bg-green-50/50 p-6 rounded-2xl border border-green-100">
                            <p class="text-[10px] font-bold text-green-600 uppercase mb-4 tracking-tighter">New State</p>
                            <pre class="text-[11px] text-green-800 whitespace-pre-wrap">{{ json_encode($activityLog->new_values, JSON_PRETTY_PRINT) }}</pre>
                        </div>
                    </div>
                </div>
            @endif
        </div>

        <div class="p-8 bg-[#F7F8FA] border-t border-gray-100 flex justify-end">
            <a href="{{ route('admin.activity-logs.index') }}" class="px-8 py-3 bg-white border border-gray-200 text-text-dark text-xs font-bold rounded-xl hover:bg-gray-50 transition-all">Back to Audit Trail</a>
        </div>
    </div>
</div>
@endsection
