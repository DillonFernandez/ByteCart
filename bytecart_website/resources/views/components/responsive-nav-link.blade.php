@props(['active'])

@php
$activeStyle = 'border-left-color:#0479FF; color:#0479FF; background-color:rgba(4,121,255,0.05);';
$inactiveHoverStyle = 'border-left-color:#0479FF; color:#0479FF; background-color:rgba(4,121,255,0.05);';

$classes = ($active ?? false)
? 'block w-full ps-3 pe-4 py-2 border-l-4 text-start text-base font-medium focus:outline-none transition duration-150 ease-in-out'
: 'block w-full ps-3 pe-4 py-2 border-l-4 border-transparent text-start text-base font-medium text-gray-600 focus:outline-none transition duration-150 ease-in-out';

$style = ($active ?? false)
? $activeStyle
: '';
@endphp

<a {{ $attributes->merge(['class' => $classes, 'style' => $style]) }}
    @if (!($active ?? false))
    onmouseover="this.style.borderLeftColor='#0479FF';this.style.color='#0479FF';this.style.backgroundColor='rgba(4,121,255,0.05)'"
    onmouseout="this.style.borderLeftColor='transparent';this.style.color='';this.style.backgroundColor=''"
    @endif>
    {{ $slot }}
</a>