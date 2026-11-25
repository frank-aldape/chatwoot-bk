<script setup>
// "Empresa ▾ / Buzón ▾" chips above the conversation list; each choice opens
// the matching company or mailbox view.
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { MAILBOXES, mailboxLabelKey } from 'dashboard/constants/mailboxes';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  managedCompanyId: { type: [String, Number], default: 0 },
  mailbox: { type: String, default: '' },
  oldestFirst: { type: Boolean, default: false },
});

const emit = defineEmits(['toggleOldestFirst']);

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const inboxes = useMapGetter('inboxes/getInboxes');

const { uiSettings, updateUISettings } = useUISettings();
const pinnedIds = computed(() =>
  (uiSettings.value.pinned_company_ids || []).map(String)
);
const isActiveCompanyPinned = computed(() =>
  pinnedIds.value.includes(String(props.managedCompanyId))
);
const togglePin = () => {
  const id = String(props.managedCompanyId);
  updateUISettings({
    pinned_company_ids: isActiveCompanyPinned.value
      ? pinnedIds.value.filter(pinnedId => pinnedId !== id)
      : [...pinnedIds.value, id],
  });
};

const openMenu = ref('');
const toggleMenu = menu => {
  openMenu.value = openMenu.value === menu ? '' : menu;
};

const companies = computed(() => {
  const byId = new Map();
  inboxes.value.forEach(({ managed_company: company }) => {
    if (company?.id) byId.set(String(company.id), company);
  });
  return [...byId.values()].sort((a, b) => a.name.localeCompare(b.name));
});

const activeCompany = computed(() =>
  companies.value.find(
    company => String(company.id) === String(props.managedCompanyId)
  )
);

const allItem = action => ({
  action,
  value: 'all',
  label: t('CHAT_LIST.SCOPE_FILTERS.ALL'),
});

const companyItems = computed(() => [
  allItem('company'),
  ...companies.value.map(company => ({
    action: 'company',
    value: String(company.id),
    label: company.name,
    isSelected: String(company.id) === String(props.managedCompanyId),
  })),
]);

const mailboxItems = computed(() => [
  allItem('mailbox'),
  ...MAILBOXES.map(mailbox => ({
    action: 'mailbox',
    value: mailbox,
    label: t(mailboxLabelKey(mailbox)),
    isSelected: mailbox === props.mailbox,
  })),
]);

const companyLabel = computed(
  () => activeCompany.value?.name || t('CHAT_LIST.SCOPE_FILTERS.COMPANY')
);
const mailboxLabel = computed(() =>
  props.mailbox
    ? t(mailboxLabelKey(props.mailbox))
    : t('CHAT_LIST.SCOPE_FILTERS.MAILBOX')
);

const onSelect = ({ action, value }) => {
  openMenu.value = '';
  const { accountId } = route.params;
  if (value === 'all') {
    router.push({ name: 'home', params: { accountId } });
  } else if (action === 'company') {
    router.push({
      name: 'managed_company_conversations',
      params: { accountId, managedCompanyId: value },
    });
  } else {
    router.push({
      name: 'mailbox_conversations',
      params: { accountId, mailbox: value },
    });
  }
};
</script>

<template>
  <div
    class="flex flex-wrap items-center gap-2 px-4 py-2 border-b border-n-weak"
  >
    <div
      v-on-click-outside="() => openMenu === 'company' && toggleMenu('company')"
      class="relative min-w-0"
    >
      <Button
        :label="companyLabel"
        icon="i-lucide-landmark"
        size="xs"
        :color="activeCompany ? 'blue' : 'slate'"
        variant="faded"
        class="max-w-48 [&>span]:truncate"
        @click="toggleMenu('company')"
      />
      <DropdownMenu
        v-if="openMenu === 'company'"
        :menu-items="companyItems"
        show-search
        :search-placeholder="$t('CHAT_LIST.SCOPE_FILTERS.SEARCH_COMPANY')"
        class="mt-1 ltr:left-0 rtl:right-0 top-full w-64 max-h-80 overflow-y-auto z-50"
        @action="onSelect"
      />
    </div>
    <Button
      v-if="activeCompany"
      v-tooltip="$t('WORKLOAD.PIN')"
      icon="i-lucide-star"
      size="xs"
      variant="ghost"
      :color="isActiveCompanyPinned ? 'amber' : 'slate'"
      @click="togglePin"
    />
    <div
      v-on-click-outside="() => openMenu === 'mailbox' && toggleMenu('mailbox')"
      class="relative min-w-0"
    >
      <Button
        :label="mailboxLabel"
        icon="i-lucide-inbox"
        size="xs"
        :color="mailbox ? 'blue' : 'slate'"
        variant="faded"
        @click="toggleMenu('mailbox')"
      />
      <DropdownMenu
        v-if="openMenu === 'mailbox'"
        :menu-items="mailboxItems"
        class="mt-1 ltr:left-0 rtl:right-0 top-full w-52 z-50"
        @action="onSelect"
      />
    </div>
    <Button
      :label="$t('CHAT_LIST.SCOPE_FILTERS.OLDEST_FIRST')"
      icon="i-lucide-arrow-up-narrow-wide"
      size="xs"
      :color="oldestFirst ? 'blue' : 'slate'"
      variant="faded"
      class="flex-shrink-0"
      @click="emit('toggleOldestFirst')"
    />
  </div>
</template>
