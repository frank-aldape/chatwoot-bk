<script setup>
// The one "loading with a message" block; replaces woot-loading-state.
// For content placeholders use components-next/skeleton/Skeleton.vue.
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  message: { type: String, default: '' },
});
</script>

<template>
  <div
    class="flex flex-col items-center justify-center gap-3 py-10 text-n-slate-11"
    role="status"
    aria-live="polite"
  >
    <Spinner :size="24" />
    <p v-if="message" class="m-0 text-sm">{{ message }}</p>
  </div>
</template>
