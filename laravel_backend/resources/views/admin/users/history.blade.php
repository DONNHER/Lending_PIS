@extends('layouts.dashboard')

@section('title', 'User History')
@section('header_title', 'Access & Audit Analysis')

@section('content')
<div class="max-w-6xl mx-auto space-y-8">
    <!-- User Overview Header -->
    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden p-8">
        <div class="flex items-center gap-6">
            <div class="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center text-primary text-2xl font-bold">
                {{ substr($user->firstname, 0, 1) }}
            </div>
            <div class="flex-1">
                <h3 class="text-text-dark font-[900] text-2xl">{{ $user->full_name }}</h3>
                <p class="text-text-muted text-sm">{{ $user->email }} | Role: <span class="uppercase font-bold text-primary">{{ $user->role }}</span></p>
                <div class="mt-4 flex gap-3">
                    <form action="{{ route('admin.users.force-logout', $user) }}" method="POST">
                        @csrf
                        <button type="submit" class="px-4 py-2 bg-error text-white text-[10px] font-bold rounded-xl shadow-lg hover:opacity-90">FORCE LOGOUT ALL DEVICES</button>
                    </form>
                    <form action="{{ route('admin.users.impersonate', $user) }}" method="POST">
                        @csrf
                        <button type="submit" class="px-4 py-2 bg-text-dark text-white text-[10px] font-bold rounded-xl shadow-lg hover:opacity-90">IMPERSONATE SESSION</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Activity Analytics -->
        <div class="lg:col-span-1 space-y-6">
            <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
                <h4 class="text-text-dark font-bold mb-6 text-sm uppercase tracking-wider">Usage Analytics</h4>
                <div class="space-y-4">
                    @foreach($topActions as $action)
                        <div>
                            <div class="flex justify-between text-[10px] font-bold mb-1">
                                <span class="text-text-dark uppercase">{{ $action->action }}</span>
                                <span class="text-primary">{{ $action->count }} hits</span>
                            </div>
                            <div class="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
                                <div class="bg-primary h-full" style="width: {{ ($action->count / $topActions->max('count')) * 100 }}%"></div>
                            </div>
                        </div>
                    @endforeach
                    @if($topActions->isEmpty())
                        <p class="text-[10px] text-text-muted italic">No activity data available yet.</p>
                    @endif
                </div>
            </div>

            <div class="bg-primary p-6 rounded-3xl shadow-lg shadow-primary/20 text-white">
                <h4 class="text-white/70 text-[10px] font-bold uppercase mb-1">Account Created</h4>
                <p class="text-xl font-black">{{ $user->created_at->format('M d, Y') }}</p>
                <p class="text-[10px] mt-2 opacity-60">Last login: {{ $user->updated_at->diffForHumans() }}</p>
            </div>
        </div>

        <!-- Login & Security History -->
        <div class="lg:col-span-2 bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden">
            <div class="p-6 border-b border-[#F0F1F5]">
                <h4 class="text-text-dark font-bold text-sm">Security Audit Trail</h4>
            </div>
            <div class="divide-y divide-[#F0F1F5]">
                @forelse($history as $log)
                    <div class="p-5 flex items-start gap-4 hover:bg-gray-50 transition-colors">
                        <div class="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center shrink-0">
                            @if(str_contains($log->action, 'Login'))
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-success" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" /></svg>
                            @else
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>
                            @endif
                        </div>
                        <div class="flex-1">
                            <div class="flex justify-between items-start mb-1">
                                <h5 class="text-sm font-bold text-text-dark">{{ $log->action }}</h5>
                                <span class="text-[10px] text-text-muted">{{ $log->created_at->format('M d, h:i A') }}</span>
                            </div>
                            <p class="text-xs text-text-muted leading-relaxed">{{ $log->description }}</p>
                            <div class="mt-2 flex gap-4 text-[9px] font-bold text-text-muted">
                                <span class="flex items-center gap-1"><svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" /></svg> {{ $log->ip_address }}</span>
                                <span class="flex items-center gap-1 truncate max-w-[200px]"><svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" /></svg> {{ $log->device_info }}</span>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="p-10 text-center text-text-muted text-sm italic">No login or security events recorded.</div>
                @endforelse
            </div>
            @if($history->hasPages())
                <div class="p-6 bg-gray-50 border-t border-[#F0F1F5]">{{ $history->links() }}</div>
            @endif
        </div>
    </div>
</div>
@endsection
