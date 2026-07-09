@props([
    'title' => 'No records found',
    'description' => 'Try adjusting your filters or adding a new entry.',
    'icon' => 'folder-open',
    'actionText' => null,
    'actionUrl' => null
])

<div class="flex flex-col items-center justify-center py-20 px-4 text-center">
    <div class="w-20 h-20 bg-gray-50 rounded-[32px] flex items-center justify-center text-gray-300 mb-6">
        @if($icon === 'folder-open')
            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
            </svg>
        @elseif($icon === 'search')
            <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
        @endif
    </div>
    <h3 class="text-lg font-bold text-text-dark mb-2">{{ $title }}</h3>
    <p class="text-sm text-text-muted max-w-xs mx-auto mb-8">{{ $description }}</p>

    @if($actionText && $actionUrl)
        <a href="{{ $actionUrl }}" class="bg-primary text-white px-8 py-3 rounded-2xl text-xs font-bold shadow-lg hover:opacity-90 transition-all">
            {{ $actionText }}
        </a>
    @endif
</div>
