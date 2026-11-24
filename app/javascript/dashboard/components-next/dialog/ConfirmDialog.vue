<script setup>
// The one confirm/delete dialog: a Dialog in alert mode driven by v-model:show,
// so it drops in where the legacy woot-delete-modal / woot-confirm-modal were.
import { ref, watch, nextTick } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

defineProps({
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  confirmLabel: { type: String, default: '' },
  cancelLabel: { type: String, default: '' },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['confirm', 'cancel']);
const show = defineModel('show', { type: Boolean, default: false });
const dialogRef = ref(null);

watch(
  show,
  async value => {
    await nextTick();
    if (value) dialogRef.value?.open();
    else dialogRef.value?.close();
  },
  { immediate: true }
);

const onClose = () => {
  if (!show.value) return;
  show.value = false;
  emit('cancel');
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    width="md"
    :title="title"
    :description="description"
    :confirm-button-label="confirmLabel"
    :cancel-button-label="cancelLabel"
    :is-loading="isLoading"
    @confirm="emit('confirm')"
    @close="onClose"
  >
    <slot />
  </Dialog>
</template>
