@extends('layouts.dashboard')

@section('title', 'Notifications')
@section('header_title', 'Notifications')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">
    <div class="flex items-center justify-between">
        <h3 class="text-text-dark font-bold text-lg">Your Alerts</h3>
        <form action="{{ route('notifications.read-all') }}" method="POST">
            @csrf
            <button type="submit" class="text-primary text-xs font-bold hover:underline">Mark all as read</button>
        </form>
    </div>

    <div class="bg-white rounded-3xl border border-[#F0F1F5] shadow-sm overflow-hidden divide-y divide-gray-50">
        @forelse($notifications as $n)
            <div class="p-6 flex items-start gap-4 hover:bg-gray-50 transition-colors {{ $n->is_unread ? 'bg-primary/5' : '' }}">
                <div class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0
                    {{ $n->category === 'security' ? 'bg-error/10 text-error' : 'bg-primary/10 text-primary' }}">
                    @if($n->category === 'security')
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m0 0v2m0-2h2m-2 0H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    @else
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>
                    @endif
                </div>
                <div class="flex-1 min-w-0">
                    <div class="flex items-center justify-between mb-1">
                        <h4 class="text-sm font-bold text-text-dark truncate">{{ $n->title }}</h4>
                        <span class="text-[10px] text-text-muted whitespace-nowrap">{{ $n->created_at->diffForHumans() }}</span>
                    </div>
                    <p class="text-xs text-text-muted leading-relaxed line-clamp-2">{{ $n->content }}</p>
                </div>
                @if($n->is_unread)
                    <form action="{{ route('notifications.read', $n) }}" method="POST">
                        @csrf
                        @method('PATCH')
                        <button type="submit" class="w-2 h-2 bg-primary rounded-full mt-2" title="Mark as read"></button>
                    </form>
                @endif
            </div>
        @empty
            <div class="p-12 text-center text-text-muted italic text-sm">No notifications found</div>
        @endforelse
    </div>

    @if($notifications->hasPages())
        <div class="pt-4">
            {{ $notifications->links() }}
        </div>
    @endif
</div>
@endsection
