@extends('layouts.dashboard')

@section('title', 'Shareholders Management')
@section('header_title', 'Shareholders Registry')

@section('breadcrumbs')
    <x-breadcrumb :items="['Shareholders' => route('admin.shareholders.index')]" />
@endsection

@section('content')
<div class="space-y-6" x-data="advancedTable()">
    <!-- Top Action Bar -->
    <div class="flex flex-col lg:flex-row lg:items-center justify-between bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm gap-4">
        <div class="flex items-center gap-4">
            <h3 class="text-text-dark text-xl font-bold">Shareholders</h3>
            <div class="flex gap-2">
                <a href="{{ route('admin.shareholders.index') }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ !request('trashed') ? 'bg-primary/10 text-primary' : 'bg-gray-50 text-text-muted' }}">Active</a>
                <a href="{{ route('admin.shareholders.index', ['trashed' => 'true']) }}" class="px-3 py-1.5 text-[10px] font-bold rounded-lg {{ request('trashed') ? 'bg-error/10 text-error' : 'bg-gray-50 text-text-muted' }}">Trash</a>
            </div>
        </div>

        <div class="flex flex-wrap gap-2">
            <button @click="showFilters = !showFilters" :class="showFilters ? 'bg-primary text-white' : 'bg-white border border-gray-200 text-text-dark'" class="px-4 py-2.5 rounded-xl text-xs font-bold shadow-sm transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" /></svg>
                Filters
            </button>

            <div class="relative" x-data="{ open: false }">
                <button @click="open = !open" class="bg-white border border-gray-200 text-text-dark px-4 py-2.5 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7" /></svg>
                    Columns
                </button>
                <div x-show="open" @click.away="open = false" x-cloak class="absolute right-0 mt-2 w-48 bg-white border border-gray-100 shadow-xl rounded-xl p-4 z-20" aria-label="Toggle Columns Visibility">
                    <p class="text-[10px] font-bold text-text-muted uppercase mb-3">Visible Columns</p>
                    <div class="space-y-2">
                        <template x-for="col in columns">
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input type="checkbox" x-model="col.visible" class="rounded text-primary focus:ring-primary h-3.5 w-3.5 border-gray-300">
                                <span class="text-xs font-medium text-text-dark" x-text="col.label"></span>
                            </label>
                        </template>
                    </div>
                </div>
            </div>

            <div class="relative" x-data="{ open: false }">
                <button @click="open = !open" class="bg-white border border-gray-200 text-text-dark px-4 py-2.5 rounded-xl text-xs font-bold shadow-sm hover:bg-gray-50 transition-all flex items-center gap-2">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" /></svg>
                    Export
                </button>
                <div x-show="open" @click.away="open = false" x-cloak class="absolute right-0 mt-2 w-40 bg-white border border-gray-100 shadow-xl rounded-xl py-2 z-10">
                    <a href="{{ request()->fullUrlWithQuery(['export' => 'csv', 'format' => 'csv']) }}" class="flex items-center gap-2 px-4 py-2 text-xs font-bold text-text-dark hover:bg-gray-50">
                        <span class="w-2 h-2 rounded-full bg-success"></span> CSV Current View
                    </a>
                    <a href="{{ request()->fullUrlWithQuery(['export' => 'pdf', 'format' => 'pdf']) }}" class="flex items-center gap-2 px-4 py-2 text-xs font-bold text-text-dark hover:bg-gray-50">
                        <span class="w-2 h-2 rounded-full bg-error"></span> PDF / Print
                    </a>
                </div>
            </div>

            <button @click="importModal = true" class="bg-secondary/10 text-secondary px-4 py-2.5 rounded-xl text-xs font-bold hover:bg-secondary hover:text-white transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" /></svg>
                Import
            </button>

            <a href="{{ route('admin.shareholders.create') }}" class="bg-primary text-white px-6 py-2.5 rounded-xl text-xs font-bold shadow-lg hover:opacity-90 transition-all flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
                Register New
            </a>
        </div>
    </div>

    <!-- Advanced Filters Drawer -->
    <div x-show="showFilters" x-collapse x-cloak class="bg-white p-8 rounded-3xl border border-[#F0F1F5] shadow-sm">
        <form action="{{ route('admin.shareholders.index') }}" method="GET" class="space-y-6">
            @if(request('trashed')) <input type="hidden" name="trashed" value="true"> @endif

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Global Search</label>
                    <input type="text" name="search" value="{{ request('search') }}" placeholder="Name, Email, Phone..." class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Status</label>
                    <select name="status" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        <option value="">All Statuses</option>
                        <option value="active" {{ request('status') == 'active' ? 'selected' : '' }}>Active</option>
                        <option value="inactive" {{ request('status') == 'inactive' ? 'selected' : '' }}>Inactive</option>
                    </select>
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Min Share Capital</label>
                    <input type="number" name="min_capital" value="{{ request('min_capital') }}" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-bold text-text-muted uppercase">Items Per Page</label>
                    <select name="per_page" class="w-full bg-[#F7F8FA] border-none rounded-xl p-3 text-sm">
                        @foreach([10, 25, 50, 100] as $count)
                            <option value="{{ $count }}" {{ request('per_page') == $count ? 'selected' : '' }}>{{ $count }} items</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="flex justify-end gap-3 pt-4 border-t border-gray-50">
                <a href="{{ route('admin.shareholders.index') }}" class="px-6 py-2.5 text-xs font-bold text-text-muted hover:text-text-dark">Reset Filters</a>
                <button type="submit" class="bg-primary text-white px-8 py-2.5 rounded-xl text-xs font-bold shadow-lg">Apply Analysis</button>
            </div>
        </form>
    </div>

    <!-- Bulk Actions Panel (Visible when items selected) -->
    <div x-show="selected.length > 0" x-transition x-cloak class="fixed bottom-10 left-1/2 transform -translate-x-1/2 bg-text-dark text-white px-8 py-4 rounded-3xl shadow-2xl flex items-center gap-8 z-[100]">
        <div class="flex items-center gap-3">
            <span class="w-6 h-6 bg-primary rounded-full flex items-center justify-center text-[10px] font-bold" x-text="selected.length"></span>
            <span class="text-xs font-bold uppercase tracking-widest">Items Selected</span>
        </div>
        <div class="h-8 w-px bg-white/10"></div>
        <div class="flex gap-4">
            <form action="{{ route('admin.shareholders.bulk') }}" method="POST" class="flex gap-3">
                @csrf
                <template x-for="id in selected">
                    <input type="hidden" name="ids[]" :value="id">
                </template>
                <button type="submit" name="action" value="activate" class="text-[10px] font-bold hover:text-primary transition-colors">ACTIVATE</button>
                <button type="submit" name="action" value="deactivate" class="text-[10px] font-bold hover:text-primary transition-colors">DEACTIVATE</button>
                <button type="submit" name="action" value="delete" class="text-[10px] font-bold text-error hover:text-red-400 transition-colors" onclick="return confirm('Soft-delete selected items?')">DELETE</button>
            </form>
        </div>
        <button @click="selected = []" class="text-white/40 hover:text-white">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
        </button>
    </div>

    <!-- Main Data Table -->
    <div class="bg-white rounded-[32px] border border-[#F0F1F5] shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left">
                <thead>
                    <tr class="bg-[#F7F8FA] text-text-muted text-[10px] font-black uppercase tracking-widest">
                        <th class="px-6 py-5 w-10">
                            <input type="checkbox" @change="toggleAll" :checked="allSelected" class="rounded text-primary focus:ring-primary border-gray-300">
                        </th>
                        <template x-for="col in columns">
                            <th x-show="col.visible" class="px-6 py-5 cursor-pointer hover:text-primary transition-colors group" @click="sort(col.key)">
                                <div class="flex items-center gap-2">
                                    <span x-text="col.label"></span>
                                    <svg x-show="sortBy === col.key" xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" :class="sortOrder === 'asc' ? '' : 'rotate-180'" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" /></svg>
                                </div>
                            </th>
                        </template>
                        <th class="px-6 py-5 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-[#F0F1F5]">
                    @forelse($shareholders as $s)
                        <tr class="hover:bg-gray-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <input type="checkbox" value="{{ $s->id }}" x-model="selected" class="rounded text-primary focus:ring-primary border-gray-300">
                            </td>
                            <td x-show="isColumnVisible('name')" class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-9 h-9 bg-primary/10 rounded-xl flex items-center justify-center text-primary text-xs font-black">
                                        {{ substr($s->firstname, 0, 1) }}
                                    </div>
                                    <div>
                                        <p class="text-sm font-bold text-text-dark">{{ $s->firstname }} {{ $s->lastname }}</p>
                                        <p class="text-[10px] text-text-muted">#{{ substr($s->id, 0, 8) }}</p>
                                    </div>
                                </div>
                            </td>
                            <td x-show="isColumnVisible('email')" class="px-6 py-4 text-xs font-medium text-text-muted">{{ $s->email }}</td>
                            <td x-show="isColumnVisible('contact')" class="px-6 py-4 text-xs font-medium text-text-dark">{{ $s->contact_number ?? 'N/A' }}</td>
                            <td x-show="isColumnVisible('capital')" class="px-6 py-4">
                                <span class="text-sm font-black text-text-dark">₱{{ number_format($s->total_share_capital, 2) }}</span>
                            </td>
                            <td x-show="isColumnVisible('status')" class="px-6 py-4">
                                <span class="px-2.5 py-1 rounded-full text-[9px] font-black uppercase tracking-tighter {{ $s->status === 'active' ? 'bg-success/10 text-success' : 'bg-gray-100 text-gray-500' }}">
                                    {{ $s->status }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-right">
                                <div class="flex justify-end items-center gap-2" x-data="{ confirmDelete: false }">
                                    @if($s->trashed())
                                        <form action="{{ route('admin.shareholders.restore', $s->id) }}" method="POST">
                                            @csrf
                                            <button type="submit" class="bg-success text-white px-4 py-1.5 rounded-lg text-[10px] font-bold shadow-sm">Restore</button>
                                        </form>
                                    @else
                                        <a href="{{ route('admin.shareholders.show', $s) }}" class="p-2 text-text-muted hover:text-primary transition-colors">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                        </a>
                                        <button @click="confirmDelete = true" class="p-2 text-text-muted hover:text-error transition-colors">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                        </button>
                                    @endif

                                    <!-- Deletion Warning Modal -->
                                    <template x-if="confirmDelete">
                                        <div class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm text-left">
                                            <div class="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl">
                                                <div class="w-16 h-16 bg-error/10 text-error rounded-full flex items-center justify-center mx-auto mb-6">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.268 17c-.77 1.333.192 3 1.732 3z" /></svg>
                                                </div>
                                                <h3 class="text-xl font-bold text-text-dark mb-2 text-center">Confirm Deletion</h3>
                                                <p class="text-text-muted text-sm mb-6">Soft-deleting <strong>{{ $s->firstname }}</strong> will move them to the trash. This action can be reversed.</p>
                                                <form action="{{ route('admin.shareholders.destroy', $s) }}" method="POST" class="space-y-4">
                                                    @csrf @method('DELETE')
                                                    <input type="password" name="confirm_password" placeholder="Verify Admin Password" required class="w-full bg-gray-50 border-none rounded-xl p-4 text-sm focus:ring-1 focus:ring-error">
                                                    <div class="flex gap-3">
                                                        <button type="button" @click="confirmDelete = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl">Cancel</button>
                                                        <button type="submit" class="flex-1 bg-error text-white font-bold py-3 rounded-xl">Delete</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </template>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7">
                                <x-empty-state
                                    title="No Shareholders Found"
                                    description="We couldn't find any shareholders matching your current filters or search query."
                                    icon="search"
                                    action-text="Clear Filters"
                                    :action-url="route('admin.shareholders.index')"
                                />
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($shareholders->hasPages())
            <div class="px-8 py-6 bg-[#F7F8FA] border-t border-[#F0F1F5]">
                {{ $shareholders->links() }}
            </div>
        @endif
    </div>

    <!-- Import Modal -->
    <div x-show="importModal" x-cloak class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
        <div class="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl" x-data="{ importing: false }">
            <h3 class="text-xl font-bold text-text-dark mb-2">Bulk Import</h3>
            <p class="text-text-muted text-sm mb-6">Upload a CSV file with columns: <strong>firstname, lastname, email, contact_number, address</strong>.</p>

            <form action="{{ route('admin.shareholders.import') }}" method="POST" enctype="multipart/form-data" class="space-y-6" @submit="importing = true">
                @csrf
                <div x-show="!importing" class="border-2 border-dashed border-gray-200 rounded-2xl p-8 text-center bg-gray-50">
                    <input type="file" name="file" required accept=".csv" class="text-xs text-text-muted">
                    <p class="text-[10px] text-text-muted mt-2">Only .csv files supported</p>
                </div>

                <!-- Progress State -->
                <div x-show="importing" class="space-y-4 py-8">
                    <div class="flex justify-between items-center mb-1">
                        <span class="text-[10px] font-bold text-primary uppercase tracking-widest">Processing Data...</span>
                        <span class="text-[10px] font-bold text-text-muted">PLEASE WAIT</span>
                    </div>
                    <div class="w-full bg-gray-100 rounded-full h-2 overflow-hidden">
                        <div class="bg-primary h-full animate-[progress_2s_ease-in-out_infinite]" style="width: 60%"></div>
                    </div>
                    <p class="text-center text-[10px] text-text-muted italic">Validating rows and checking for duplicates.</p>
                </div>

                <div class="flex gap-3" x-show="!importing">
                    <button type="button" @click="importModal = false" class="flex-1 bg-gray-100 text-text-muted font-bold py-3 rounded-xl">Cancel</button>
                    <button type="submit" class="flex-1 bg-primary text-white font-bold py-3 rounded-xl shadow-lg">Start Import</button>
                </div>
            </form>
        </div>
    </div>

    <style>
        @keyframes progress {
            0% { transform: translateX(-100%); }
            100% { transform: translateX(200%); }
        }
    </style>
</div>
@endsection

@push('scripts')
<script>
function advancedTable() {
    return {
        showFilters: false,
        importModal: false,
        selected: [],
        sortBy: '{{ request('sort_by', 'created_at') }}',
        sortOrder: '{{ request('sort_order', 'desc') }}',
        columns: [
            { key: 'name', label: 'Full Name', visible: true },
            { key: 'email', label: 'Email Address', visible: true },
            { key: 'contact', label: 'Contact', visible: true },
            { key: 'capital', label: 'Capital', visible: true },
            { key: 'status', label: 'Status', visible: true }
        ],

        get allSelected() {
            const checkboxes = document.querySelectorAll('tbody input[type="checkbox"]');
            return checkboxes.length > 0 && this.selected.length === checkboxes.length;
        },

        toggleAll() {
            const checkboxes = document.querySelectorAll('tbody input[type="checkbox"]');
            if (this.allSelected) {
                this.selected = [];
            } else {
                this.selected = Array.from(checkboxes).map(cb => cb.value);
            }
        },

        isColumnVisible(key) {
            const col = this.columns.find(c => col.key === key);
            return col ? col.visible : true;
        },

        sort(column) {
            if (this.sortBy === column) {
                this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
            } else {
                this.sortBy = column;
                this.sortOrder = 'asc';
            }
            this.applySort();
        },

        applySort() {
            const url = new URL(window.location.href);
            url.searchParams.set('sort_by', this.sortBy);
            url.searchParams.set('sort_order', this.sortOrder);
            window.location.href = url.toString();
        },

        isColumnVisible(key) {
            return this.columns.find(c => c.key === key)?.visible ?? true;
        }
    }
}
</script>
@endpush
