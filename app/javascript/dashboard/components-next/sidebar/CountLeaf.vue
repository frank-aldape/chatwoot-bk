<script setup>
// Sidebar row with a trailing open-conversation count (mailboxes, companies).
import Icon from 'next/icon/Icon.vue';

defineProps({
  label: { type: String, required: true },
  icon: { type: String, default: '' },
  iconClass: { type: String, default: '' },
  dot: { type: String, default: '' },
  active: { type: Boolean, default: false },
  count: { type: Number, default: 0 },
});
</script>

<template>
  <Icon
    v-if="icon"
    :icon="icon"
    class="size-4 inline-block flex-shrink-0"
    :class="iconClass"
  />
  <span
    v-else-if="dot"
    class="size-2 rounded-full flex-shrink-0"
    :class="dot"
  />
  <div class="flex-1 truncate min-w-0" :class="{ 'text-n-slate-10': !count }">
    {{ label }}
  </div>
  <span
    v-if="count"
    class="flex-shrink-0 px-1.5 text-xs font-semibold rounded-full bg-n-alpha-2 text-n-slate-12"
    :class="{ 'bg-n-solid-blue text-n-blue-text': active }"
  >
    {{ count }}
  </span>
</template>
