@extends('layouts.dashboard')

@section('title', 'System Backups')
@section('header_title', 'Data Preservation')

@section('content')
<div class="max-w-5xl mx-auto space-y-8">
    <!-- Header with Manual Triggers -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <div class="flex flex-col md:flex-row items-center justify-between gap-6">
            <div>
                <h3 class="text-text-dark font-bold text-xl">Backup Center</h3>
                <p class="text-text-muted text-sm mt-1">Manual snapshots and automated schedule management</p>
                <div class="mt-4 flex items-center gap-2">
                    <span class="px-3 py-1 bg-primary/10 text-primary text-[10px] font-bold rounded-full uppercase">30-Day Retention Policy Active</span>
                </div>
            </div>

            <div class="flex flex-wrap gap-3">
                <form action="{{ route('admin.backups.run') }}" method="POST">
                    @csrf
                    <input type="hidden" name="type" value="db">
                    <button type="submit" class="bg-white border border-gray-200 text-text-dark px-5 py-2.5 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4" /></svg>
                        DB Backup
                    </button>
                </form>

                <form action="{{ route('admin.backups.run') }}" method="POST">
                    @csrf
                    <input type="hidden" name="type" value="files">
                    <button type="submit" class="bg-white border border-gray-200 text-text-dark px-5 py-2.5 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" /></svg>
                        Files Backup
                    </button>
                </form>

                <form action="{{ route('admin.backups.run') }}" method="POST">
                    @csrf
                    <input type="hidden" name="type" value="full">
                    <button type="submit" class="bg-primary text-white px-6 py-2.5 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-7 0V4" /></svg>
                        Full Snapshot
                    </button>
                </form>
            </div>
        </div>
    </div>

    <!-- Backup List -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5]">
            <h4 class="text-text-dark font-bold text-sm">Stored Archives</h4>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[10px] font-bold uppercase tracking-wider">
                        <th class="px-8 py-4">Filename</th>
                        <th class="px-8 py-4">Size</th>
                        <th class="px-8 py-4">Created Date</th>
                        <th class="px-8 py-4">Integrity</th>
                        <th class="px-8 py-4 text-right">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($backups as $b)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-8 py-5">
                                <div class="flex items-center gap-3">
                                    <div class="w-9 h-9 bg-gray-100 rounded-xl flex items-center justify-center text-text-muted">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" /></svg>
                                    </div>
                                    <span class="text-sm font-semibold text-text-dark">{{ $b->name }}</span>
                                </div>
                            </td>
                            <td class="px-8 py-5 text-xs text-text-muted font-medium">{{ $b->size }}</td>
                            <td class="px-8 py-5">
                                <p class="text-xs text-text-dark font-bold">{{ $b->created_at->format('M d, Y') }}</p>
                                <p class="text-[10px] text-text-muted">{{ $b->created_at->format('h:i A') }}</p>
                            </td>
                            <td class="px-8 py-5">
                                <span class="flex items-center gap-1.5 text-success font-bold text-[10px] uppercase">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" /></svg>
                                    Verified
                                </span>
                            </td>
                            <td class="px-8 py-5 text-right">
                                <a href="{{ route('admin.backups.download', $b->name) }}" class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-gray-50 text-text-muted hover:bg-primary hover:text-white transition-all">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4-4m0 0L8 8m4-4v12" /></svg>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-8 py-20 text-center">
                                <div class="w-16 h-16 bg-gray-50 rounded-full mx-auto flex items-center justify-center text-gray-300 mb-4">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-7 0V4" /></svg>
                                </div>
                                <p class="text-text-muted text-sm italic">No backup archives found in local storage</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Backup Configuration Info -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <h5 class="text-xs font-bold text-text-muted uppercase tracking-widest mb-4">DB Schedule</h5>
            <p class="text-sm font-bold text-text-dark">Weekly (Mondays)</p>
            <p class="text-[11px] text-text-muted mt-1">Next: {{ now()->next(1)->at('02:00')->format('M d, Y h:i A') }}</p>
        </div>
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <h5 class="text-xs font-bold text-text-muted uppercase tracking-widest mb-4">Files Schedule</h5>
            <p class="text-sm font-bold text-text-dark">Weekly (Sundays)</p>
            <p class="text-[11px] text-text-muted mt-1">Next: {{ now()->next(0)->at('03:00')->format('M d, Y h:i A') }}</p>
        </div>
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <h5 class="text-xs font-bold text-text-muted uppercase tracking-widest mb-4">Full System</h5>
            <p class="text-sm font-bold text-text-dark">Monthly (1st Day)</p>
            <p class="text-[11px] text-text-muted mt-1">Next: {{ now()->nextOfMonth()->startOfMonth()->at('04:00')->format('M d, Y h:i A') }}</p>
        </div>
    </div>
</div>
@endsection
