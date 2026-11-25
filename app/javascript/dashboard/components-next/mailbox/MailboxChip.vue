<script setup>
// Colored mailbox tag (Ventas, Facturación…); `label` overrides the text and
// `icon` turns it into the rounded pill used in headers.
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { mailboxColors, mailboxLabelKey } from 'dashboard/constants/mailboxes';

const props = defineProps({
  mailbox: { type: String, required: true },
  label: { type: String, default: '' },
  icon: { type: Boolean, default: false },
});

const { t } = useI18n();
const text = computed(() => props.label || t(mailboxLabelKey(props.mailbox)));
</script>

<template>
  <span
    class="inline-flex items-center gap-1 min-w-0 px-2 py-0.5 text-xs font-medium"
    :class="[mailboxColors(mailbox).chip, icon ? 'rounded-full' : 'rounded-md']"
  >
    <span v-if="icon" class="i-lucide-mail size-3 flex-shrink-0" />
    <span class="truncate">{{ text }}</span>
  </span>
</template>
