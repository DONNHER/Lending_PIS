@extends('layouts.dashboard')

@section('title', 'User Management')
@section('header_title', 'System Users')

@section('breadcrumbs')
    <x-breadcrumb :items="['Users' => route('admin.users.index')]" />
@endsection

@section('content')
<div class="space-y-6" x-data="advancedTable()">
    <!-- Success/Error Messages for Import -->
    @if(session('import_errors'))
        <div class="p-4 bg-error/10 border border-error/20 rounded-2xl mb-6">
            <div class="flex items-center gap-2 text-error font-bold text-sm mb-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.268 17c-.77 1.333.192 3 1.732 3z" /></svg>
                Bulk Import Warnings
            </div>
            <ul class="text-[10px] text-text-muted space-y-1 max-h-32 overflow-y-auto">
                @foreach(session('import_errors') as $error)
                    <li>• {{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <!-- Top Action Bar -->
    <div class="flex flex-col lg:flex-row lg:items-center justify-between bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm gap-4">
        <div class="flex items-center gap-4">
            <h3 class="text-text-dark text-xl font-bold">All Accounts</h3>
            <div class="flex gap-2">
                <a href="{{ route('admin.users.index') }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ !request('trashed') ? 'bg-primary/10 text-primary' : 'bg-gray-50 text-text-muted' }}">Active</a>
                <a href="{{ route('admin.users.index', ['trashed' => 'true']) }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ request('trashed') ? 'bg-error/10 text-error' : 'bg-gray-50 text-text-muted' }}">Trash</a>
            </div>
        </div>

        <div class="flex flex-wrap gap-2">
            <button @click="showFilters = !showFilters" :class="showFilters ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-text-dark'" class="px-4 py-2.5 rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" /></svg>
                Filters
            </button>

            <a href="{{ request()->fullUrlWithQuery(['export' => 'true']) }}" class="bg-white border border-gray-200 text-text-dark px-4 py-2.5 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
                Export
            </a>

            <button @click="importModal = true" class="bg-secondary/10 text-secondary px-4 py-2.5 rounded-xl text-xs font-bold hover:bg-secondary hover:text-white transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" /></svg>
                Import
            </button>

            <a href="{{ route('register') }}" class="bg-primary text-white px-6 py-2.5 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" /></svg>
                Add Account
            </a>
        </div>
    </div>

    <!-- Filters Drawer -->
    <div x-show="showFilters" x-collapse x-cloak class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm">
        <form action="{{ route('admin.users.index') }}" method="GET" class="space-y-6">
            @if(request('trashed')) <input type="hidden" name="trashed" value="true"> @endif
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Search</label>
                    <input type="text" name="search" value="{{ request('search') }}" placeholder="Name, Email, Username..." class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Role Filter</label>
                    <select name="role" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        <option value="">All Roles</option>
                        <option value="admin" {{ request('role') == 'admin' ? 'selected' : '' }}>Admin</option>
                        <option value="staff" {{ request('role') == 'staff' ? 'selected' : '' }}>Staff</option>
                        <option value="member" {{ request('role') == 'member' ? 'selected' : '' }}>Member</option>
                    </select>
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Pagination</label>
                    <select name="per_page" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        @foreach([10, 15, 25, 50, 100] as $count)
                            <option value="{{ $count }}" {{ request('per_page') == $count ? 'selected' : '' }}>{{ $count }} rows</option>
                        @endforeach
                    </select>
                </div>
            </div>
            <div class="flex justify-end pt-4 border-t border-gray-50">
                <button type="submit" class="bg-primary text-white px-8 py-2.5 rounded-xl text-xs font-bold shadow-lg">Filter Users</button>
            </div>
        </form>
    </div>

    <!-- Bulk Actions -->
    <div x-show="selected.length > 0" x-transition x-cloak class="fixed bottom-10 left-1/2 transform -translate-x-1/2 bg-text-dark text-white px-8 py-4 rounded-3xl shadow-2xl flex items-center gap-8 z-[100]">
        <div class="flex items-center gap-3">
            <span class="w-6 h-6 bg-primary rounded-full flex items-center justify-center text-[10px] font-bold" x-text="selected.length"></span>
            <span class="text-xs font-bold uppercase">Users Selected</span>
        </div>
        <form action="{{ route('admin.users.bulk') }}" method="POST" class="flex gap-4">
            @csrf
            <template x-for="id in selected">
                <input type="hidden" name="ids[]" :value="id">
            </template>
            <button type="submit" name="action" value="activate" class="text-[10px] font-bold hover:text-primary transition-colors">ACTIVATE</button>
            <button type="submit" name="action" value="deactivate" class="text-[10px] font-bold hover:text-primary transition-colors">DEACTIVATE</button>
            <button type="submit" name="action" value="force-logout" class="text-[10px] font-bold hover:text-primary transition-colors">FORCE LOGOUT</button>
            <button type="submit" name="action" value="delete" class="text-[10px] font-bold text-error hover:text-red-400 transition-colors" onclick="return confirm('Bulk delete these users?')">DELETE</button>
        </form>
        <button @click="selected = []" class="text-white/40 hover:text-white"><svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg></button>
    </div>

    <!-- Import Modal -->
    <div x-show="importModal" x-cloak class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
        <div class="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl" x-data="{ importing: false }">
            <h3 class="text-xl font-bold text-text-dark mb-2">Bulk User Import</h3>
            <p class="text-text-muted text-sm mb-6">CSV structure: <strong>username, email, firstname, lastname, role</strong>.</p>

            <form action="{{ route('admin.users.import') }}" method="POST" enctype="multipart/form-data" class="space-y-6" @submit="importing = true">
                @csrf
                <div x-show="!importing" class="border-2 border-dashed border-gray-200 rounded-2xl p-8 text-center bg-gray-50">
                    <input type="file" name="file" required accept=".csv" class="text-xs text-text-muted">
                </div>

                <div x-show="importing" class="space-y-4 py-4">
                    <div class="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
                        <div class="bg-primary h-full animate-[progress_2s_infinite]" style="width: 50%"></div>
                    </div>
                    <p class="text-center text-[10px] text-text-muted">Syncing user directory...</p>
                </div>

                <div class="flex gap-3" x-show="!importing">
                    <button type="button" @click="importModal = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl uppercase text-xs">Cancel</button>
                    <button type="submit" class="flex-1 bg-primary text-white font-bold py-3 rounded-xl shadow-lg uppercase text-xs">Start Import</button>
                </div>
            </form>
        </div>
    </div>

    <div class="bg-white rounded-[32px] border border-[#F0F1F5] shadow-sm overflow-hidden">
        <!-- Table Skeleton -->
        <div x-show="loading" x-cloak>
            <x-skeleton type="row" count="5" />
        </div>

        <div class="overflow-x-auto" x-show="!loading">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[10px] font-black uppercase tracking-widest">
                        <th class="px-6 py-5 w-10">
                            <input type="checkbox" @change="toggleAll" :checked="allSelected" class="rounded text-primary focus:ring-primary border-gray-300">
                        </th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('firstname')">User Full Name</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('role')">System Role</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('status')">Current Status</th>
                        <th class="px-6 py-5 cursor-pointer" @click="sort('updated_at')">Last Sync</th>
                        <th class="px-6 py-5 text-right">Action</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($users as $user)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <input type="checkbox" value="{{ $user->id }}" x-model="selected" class="rounded text-primary focus:ring-primary border-gray-300">
                            </td>
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
                                        <p class="text-sm font-bold text-text-dark">{{ $user->firstname }} {{ $user->lastname }}</p>
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
                                <div class="flex justify-end gap-2" x-data="{ open: false, editModal: false, confirmDelete: false }">
                                    @if($user->trashed())
                                        <form action="{{ route('admin.users.restore', $user->id) }}" method="POST">
                                            @csrf
                                            <button type="submit" class="bg-success/10 text-success px-3 py-1.5 rounded-lg text-[10px] font-bold hover:bg-success hover:text-white transition-all">
                                                Restore
                                            </button>
                                        </form>
                                    @else
                                        <button @click="open = !open" class="text-text-muted hover:text-primary transition-colors">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" /></svg>
                                        </button>
                                        <div x-show="open" @click.away="open = false" x-cloak class="absolute mt-8 bg-white border border-gray-100 shadow-xl rounded-xl py-2 z-10 min-w-[150px]">
                                            <button @click="editModal = true; open = false" class="w-full text-left px-4 py-2 text-[11px] font-bold text-text-dark hover:bg-gray-50 flex items-center gap-2">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                                                Edit Permissions
                                            </button>
                                            <a href="{{ route('admin.users.history', $user) }}" class="w-full text-left px-4 py-2 text-[11px] font-bold text-text-dark hover:bg-gray-50 flex items-center gap-2">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2m0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>
                                                Analytics & History
                                            </a>
                                            <form action="{{ route('admin.users.impersonate', $user) }}" method="POST">
                                                @csrf
                                                <button type="submit" class="w-full text-left px-4 py-2 text-[11px] font-bold text-text-dark hover:bg-gray-50 flex items-center gap-2">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" /></svg>
                                                    Impersonate
                                                </button>
                                            </form>
                                            <div class="h-px bg-gray-50 my-1"></div>
                                            <button @click="confirmDelete = true; open = false" class="w-full text-left px-4 py-2 text-[11px] font-bold text-error hover:bg-error/5 flex items-center gap-2">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                                Delete Account
                                            </button>
                                        </div>
                                    @endif

                                    <!-- Edit User Modal -->
                                    <template x-if="editModal">
                                        <div class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm text-left">
                                            <div class="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl">
                                                <h3 class="text-xl font-bold text-text-dark mb-6">Edit System Permissions</h3>
                                                <form action="{{ route('admin.users.update', $user) }}" method="POST" class="space-y-4">
                                                    @csrf @method('PUT')
                                                    <input type="hidden" name="version" value="{{ $user->version }}">

                                                    <div class="grid grid-cols-2 gap-4">
                                                        <div class="space-y-1">
                                                            <label class="text-[10px] font-bold text-text-muted uppercase">First Name</label>
                                                            <input type="text" name="firstname" value="{{ $user->firstname }}" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                                                        </div>
                                                        <div class="space-y-1">
                                                            <label class="text-[10px] font-bold text-text-muted uppercase">Last Name</label>
                                                            <input type="text" name="lastname" value="{{ $user->lastname }}" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                                                        </div>
                                                    </div>

                                                    <div class="space-y-1">
                                                        <label class="text-[10px] font-bold text-text-muted uppercase">System Role</label>
                                                        <select name="role" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                                                            <option value="admin" {{ $user->role === 'admin' ? 'selected' : '' }}>Administrator</option>
                                                            <option value="staff" {{ $user->role === 'staff' ? 'selected' : '' }}>Staff / Cashier</option>
                                                            <option value="member" {{ $user->role === 'member' ? 'selected' : '' }}>Shareholder Member</option>
                                                        </select>
                                                    </div>

                                                    <div class="space-y-1">
                                                        <label class="text-[10px] font-bold text-text-muted uppercase">Account Status</label>
                                                        <select name="status" required class="w-full bg-gray-50 border-none rounded-xl p-3 text-sm">
                                                            <option value="active" {{ $user->status === 'active' ? 'selected' : '' }}>Active</option>
                                                            <option value="inactive" {{ $user->status === 'inactive' ? 'selected' : '' }}>Inactive</option>
                                                            <option value="suspended" {{ $user->status === 'suspended' ? 'selected' : '' }}>Suspended</option>
                                                        </select>
                                                    </div>

                                                    <div class="flex gap-3 pt-4">
                                                        <button type="button" @click="editModal = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl uppercase text-xs">Cancel</button>
                                                        <button type="submit" class="flex-1 bg-primary text-white font-bold py-3 rounded-xl shadow-lg uppercase text-xs">Save Update</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </template>

                                    <template x-if="confirmDelete">
                                        <div class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
                                            <div class="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl text-center">
                                                <div class="w-16 h-16 bg-error/10 text-error rounded-full flex items-center justify-center mx-auto mb-6">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                                </div>
                                                <h3 class="text-xl font-bold text-text-dark mb-2">Confirm Delete</h3>
                                                <p class="text-text-muted text-sm mb-6">Soft-delete <strong>{{ $user->firstname }}</strong>? They will lose dashboard access.</p>
                                                <form action="{{ route('admin.users.destroy', $user) }}" method="POST" class="flex gap-3">
                                                    @csrf @method('DELETE')
                                                    <button type="button" @click="confirmDelete = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl">Cancel</button>
                                                    <button type="submit" class="flex-1 bg-error text-white font-bold py-3 rounded-xl">Delete</button>
                                                </form>
                                            </div>
                                        </div>
                                    </template>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        @if($users->hasPages())
            <div class="px-8 py-6 bg-[#F7F8FA] border-t border-[#F0F1F5]">{{ $users->links() }}</div>
        @endif
    </div>
</div>
@endsection

@push('scripts')
<script>
function advancedTable() {
    return {
        showFilters: false,
        importModal: false,
        loading: false,
        selected: [],
        sortBy: '{{ request('sort_by', 'created_at') }}',
        sortOrder: '{{ request('sort_order', 'desc') }}',
        get allSelected() {
            const checkboxes = document.querySelectorAll('tbody input[type="checkbox"]');
            return checkboxes.length > 0 && this.selected.length === checkboxes.length;
        },
        toggleAll() {
            const checkboxes = document.querySelectorAll('tbody input[type="checkbox"]');
            this.selected = this.allSelected ? [] : Array.from(checkboxes).map(cb => cb.value);
        },
        sort(column) {
            this.loading = true;
            this.sortOrder = (this.sortBy === column && this.sortOrder === 'asc') ? 'desc' : 'asc';
            this.sortBy = column;
            const url = new URL(window.location.href);
            url.searchParams.set('sort_by', this.sortBy);
            url.searchParams.set('sort_order', this.sortOrder);
            window.location.href = url.toString();
        }
    }
}
</script>
@endpush
