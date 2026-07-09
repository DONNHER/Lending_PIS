@props(['type' => 'row', 'count' => 1])

<div class="animate-pulse space-y-4">
    @if($type === 'row')
        @for($i = 0; $i < $count; $i++)
            <div class="flex items-center space-x-4 px-6 py-4">
                <div class="w-10 h-10 bg-gray-100 rounded-xl"></div>
                <div class="flex-1 space-y-2">
                    <div class="h-3 bg-gray-100 rounded-full w-1/4"></div>
                    <div class="h-2 bg-gray-100 rounded-full w-1/2"></div>
                </div>
                <div class="h-3 bg-gray-100 rounded-full w-20"></div>
            </div>
        @endfor
    @elseif($type === 'card')
        <div class="bg-white p-6 rounded-3xl border border-[#F0F1F5] shadow-sm">
            <div class="flex items-center justify-between mb-4">
                <div class="w-10 h-10 bg-gray-100 rounded-xl"></div>
                <div class="h-4 bg-gray-100 rounded-full w-16"></div>
            </div>
            <div class="h-2 bg-gray-100 rounded-full w-1/2 mb-2"></div>
            <div class="h-6 bg-gray-100 rounded-full w-3/4"></div>
        </div>
    @endif
</div>
