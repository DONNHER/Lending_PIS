@extends('layouts.dashboard')

@section('title', 'System Backups')
@section('header_title', 'Data Preservation')

@section('content')
<div class="max-w-4xl mx-auto space-y-8">
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-8 border-b border-gray-100 flex items-center justify-between">
            <div>
                <h3 class="text-text-dark font-bold text-lg">Snapshot Management</h3>
                <p class="text-text-muted text-sm">Create and manage database backups</p>
            </div>
            <form action="{{ route('admin.backups.run') }}" method="POST">
                @csrf
                <button type="submit" class="bg-primary text-white px-6 py-2.5 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
                    Run Manual Backup
                </button>
            </form>
        </div>

        <div class="p-8">
            <div class="bg-[#F7F8FA] border-2 border-dashed border-gray-200 rounded-3xl p-12 text-center">
                <div class="w-16 h-16 bg-white rounded-2xl shadow-sm mx-auto flex items-center justify-center text-gray-300 mb-4">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" /></svg>
                </div>
                <h4 class="text-text-dark font-bold">No snapshots found</h4>
                <p class="text-text-muted text-xs mt-2 max-w-xs mx-auto">Backups are automatically performed weekly. You can manually trigger one using the button above.</p>
            </div>
        </div>
    </div>
</div>
@endsection
