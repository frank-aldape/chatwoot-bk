<script setup>
// The one pill/chip: status, mailbox, company and count tags across the app.
import { computed } from 'vue';

const props = defineProps({
  label: { type: [String, Number], default: '' },
  color: {
    type: String,
    default: 'slate',
    validator: value =>
      ['slate', 'blue', 'teal', 'amber', 'ruby', 'iris'].includes(value),
  },
  size: {
    type: String,
    default: 'sm',
    validator: value => ['sm', 'md'].includes(value),
  },
  // Icon class, e.g. i-lucide-mail
  icon: { type: String, default: '' },
});

// Full class strings so Tailwind keeps them.
const COLORS = {
  slate: 'bg-n-alpha-2 text-n-slate-12',
  blue: 'bg-n-blue-3 text-n-blue-11',
  teal: 'bg-n-teal-3 text-n-teal-11',
  amber: 'bg-n-amber-3 text-n-amber-11',
  ruby: 'bg-n-ruby-3 text-n-ruby-11',
  iris: 'bg-n-iris-3 text-n-iris-11',
};

const SIZES = {
  sm: 'gap-1 px-2 py-0.5 text-xs',
  md: 'gap-1.5 px-2.5 py-1 text-sm',
};

const classes = computed(() => [COLORS[props.color], SIZES[props.size]]);
</script>

<template>
  <span
    class="inline-flex items-center font-medium rounded-full whitespace-nowrap"
    :class="classes"
  >
    <span
      v-if="icon"
      :class="icon"
      class="size-3.5 flex-shrink-0"
      aria-hidden="true"
    />
    <slot>{{ label }}</slot>
  </span>
</template>
