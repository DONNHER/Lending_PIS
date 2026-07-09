@extends('layouts.dashboard')

@section('title', 'User Management')
@section('header_title', 'System Users')

@section('content')
<div class="space-y-6">
    <div class="flex items-center justify-between">
        <h3 class="text-text-dark font-bold text-lg">All Accounts</h3>
        <a href="{{ route('register') }}" class="bg-primary text-white px-4 py-2 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all">Add New User</a>
    </div>

    <div class="bg-white rounded-2xl border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="p-6 border-b border-[#F0F1F5] flex flex-col md:flex-row gap-4 justify-between">
            <form action="{{ route('admin.users.index') }}" method="GET" class="relative max-w-md w-full">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                </div>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search name or email..." class="w-full bg-[#F7F8FA] border-none rounded-xl py-2.5 pl-10 pr-4 text-sm focus:ring-1 focus:ring-primary">
            </form>
            <div class="flex gap-2">
                <a href="{{ route('admin.users.index', ['role' => 'admin']) }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ request('role') == 'admin' ? 'bg-primary/10 text-primary' : 'bg-gray-50 text-text-muted' }}">Admins</a>
                <a href="{{ route('admin.users.index', ['role' => 'staff']) }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ request('role') == 'staff' ? 'bg-primary/10 text-primary' : 'bg-gray-50 text-text-muted' }}">Staff</a>
                <a href="{{ route('admin.users.index', ['role' => 'member']) }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ request('role') == 'member' ? 'bg-primary/10 text-primary' : 'bg-gray-50 text-text-muted' }}">Members</a>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[11px] font-bold uppercase tracking-wider">
                        <th class="px-6 py-4">User</th>
                        <th class="px-6 py-4">Role</th>
                        <th class="px-6 py-4">Status</th>
                        <th class="px-6 py-4">Last Active</th>
                        <th class="px-6 py-4 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @foreach($users as $user)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 bg-gray-100 rounded-full overflow-hidden flex items-center justify-center">
                                        @if($user->avatar_url)
                                            <img src="{{ $user->avatar_url }}" class="w-full h-full object-cover">
                                        @else
                                            <span class="text-[10px] font-bold text-gray-400">{{ substr($user->firstname, 0, 1) }}</span>
                                        @endif
                                    </div>
                                    <div>
                                        <p class="text-sm font-bold text-text-dark">{{ $user->full_name }}</p>
                                        <p class="text-[10px] text-text-muted">{{ $user->email }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-0.5 rounded-lg text-[9px] font-black uppercase tracking-tighter
                                    {{ $user->role === 'admin' ? 'bg-red-100 text-red-600' : '' }}
                                    {{ $user->role === 'staff' ? 'bg-blue-100 text-blue-600' : '' }}
                                    {{ $user->role === 'member' ? 'bg-gray-100 text-gray-600' : '' }}
                                ">{{ $user->role }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-1.5">
                                    <div class="w-1.5 h-1.5 rounded-full {{ $user->status === 'active' ? 'bg-success' : 'bg-gray-300' }}"></div>
                                    <span class="text-xs font-medium text-text-dark capitalize">{{ $user->status }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4 text-[10px] text-text-muted">{{ $user->updated_at->diffForHumans() }}</td>
                            <td class="px-6 py-4 text-right">
                                <div class="flex justify-end gap-2" x-data="{ open: false }">
                                    <button @click="open = !open" class="text-text-muted hover:text-primary transition-colors">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" /></svg>
                                    </button>
                                    <div x-show="open" @click.away="open = false" class="absolute mt-8 bg-white border border-gray-100 shadow-xl rounded-xl py-2 z-10 min-w-[120px]">
                                        <form action="{{ route('admin.users.status', $user) }}" method="POST">
                                            @csrf
                                            @method('PATCH')
                                            <input type="hidden" name="status" value="{{ $user->status === 'active' ? 'inactive' : 'active' }}">
                                            <button type="submit" class="w-full text-left px-4 py-2 text-[11px] font-bold text-text-dark hover:bg-gray-50">
                                                {{ $user->status === 'active' ? 'Deactivate' : 'Activate' }}
                                            </button>
                                        </form>
                                    </div>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
