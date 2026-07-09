@props(['items'])

<nav aria-label="Breadcrumb" class="mb-6">
    <ol class="flex items-center space-x-2 text-[10px] font-bold uppercase tracking-widest text-text-muted">
        <li>
            <a href="{{ route('dashboard') }}" class="hover:text-primary transition-colors flex items-center gap-1">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
                Dashboard
            </a>
        </li>
        @foreach($items as $label => $link)
            <li class="flex items-center space-x-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 opacity-40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
                @if($loop->last)
                    <span class="text-text-dark">{{ $label }}</span>
                @else
                    <a href="{{ $link }}" class="hover:text-primary transition-colors">{{ $label }}</a>
                @endif
            </li>
        @endforeach
    </ol>
</nav>
