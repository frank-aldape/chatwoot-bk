<script setup>
// "Carga por empresa y buzón": open conversations as a company x mailbox heatmap.
import { computed, ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import ConversationApi from 'dashboard/api/inbox/conversation';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { MAILBOXES, mailboxLabelKey } from 'dashboard/constants/mailboxes';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const { uiSettings, updateUISettings } = useUISettings();
const pinnedIds = computed(() =>
  (uiSettings.value.pinned_company_ids || []).map(String)
);
const isPinned = companyId => pinnedIds.value.includes(String(companyId));
const togglePin = companyId => {
  const id = String(companyId);
  updateUISettings({
    pinned_company_ids: isPinned(id)
      ? pinnedIds.value.filter(pinnedId => pinnedId !== id)
      : [...pinnedIds.value, id],
  });
};

const rows = ref([]);
const isLoading = ref(true);
const search = ref('');

ConversationApi.loadMatrix()
  .then(({ data }) => {
    rows.value = data;
  })
  .finally(() => {
    isLoading.value = false;
  });

const companies = computed(() => {
  const byId = new Map();
  rows.value.forEach(row => {
    const company = byId.get(row.company_id) || {
      id: row.company_id,
      name: row.company_name,
      total: 0,
      unassigned: 0,
      cells: {},
    };
    company.total += row.count;
    company.unassigned += row.unassigned;
    company.cells[row.mailbox] = row.count;
    byId.set(row.company_id, company);
  });
  const query = search.value.trim().toLowerCase();
  return [...byId.values()]
    .filter(company => company.name.toLowerCase().includes(query))
    .sort((a, b) => b.total - a.total || a.name.localeCompare(b.name));
});

const mailboxTotals = computed(() =>
  rows.value.reduce((totals, row) => {
    totals[row.mailbox] = (totals[row.mailbox] || 0) + row.count;
    return totals;
  }, {})
);

const busiestMailbox = computed(() => {
  const [mailbox] =
    Object.entries(mailboxTotals.value).sort((a, b) => b[1] - a[1])[0] || [];
  return mailbox ? t(mailboxLabelKey(mailbox)) : '—';
});

const kpis = computed(() => [
  {
    key: 'OPEN',
    value: rows.value.reduce((sum, row) => sum + row.count, 0),
  },
  {
    key: 'UNASSIGNED',
    value: rows.value.reduce((sum, row) => sum + row.unassigned, 0),
  },
  { key: 'COMPANIES', value: companies.value.length },
  { key: 'BUSIEST_MAILBOX', value: busiestMailbox.value },
]);

const cellClass = count => {
  if (!count) return 'text-n-slate-9';
  if (count <= 2) return 'bg-n-blue-3 text-n-blue-12';
  if (count <= 5) return 'bg-n-blue-5 text-n-blue-12';
  if (count <= 10) return 'bg-n-blue-7 text-n-blue-12';
  return 'bg-n-blue-10 text-white';
};

const openCompany = companyId => {
  router.push({
    name: 'managed_company_conversations',
    params: { accountId: route.params.accountId, managedCompanyId: companyId },
  });
};
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-auto bg-n-background p-6">
    <div class="flex flex-wrap items-center justify-between gap-3 mb-6">
      <h1 class="text-xl font-medium text-n-slate-12">
        {{ $t('WORKLOAD.TITLE') }}
      </h1>
      <input
        v-model="search"
        type="search"
        class="reset-base h-8 w-64 rounded-lg bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
        :placeholder="$t('WORKLOAD.SEARCH')"
      />
    </div>

    <div class="grid grid-cols-2 gap-3 mb-6 md:grid-cols-4">
      <div
        v-for="kpi in kpis"
        :key="kpi.key"
        class="rounded-xl p-4 bg-n-solid-2 outline outline-1 outline-n-weak"
      >
        <p class="text-xs text-n-slate-11">
          {{ $t(`WORKLOAD.KPI.${kpi.key}`) }}
        </p>
        <p class="mt-1 text-2xl font-semibold truncate text-n-slate-12">
          {{ kpi.value }}
        </p>
      </div>
    </div>

    <div v-if="isLoading" class="flex justify-center py-10">
      <Spinner />
    </div>
    <p
      v-else-if="!companies.length"
      class="py-10 text-sm text-center text-n-slate-11"
    >
      {{ $t('WORKLOAD.EMPTY') }}
    </p>
    <div
      v-else
      class="overflow-x-auto rounded-xl outline outline-1 outline-n-weak"
    >
      <table class="w-full text-sm border-collapse">
        <thead>
          <tr class="bg-n-solid-2 text-n-slate-11">
            <th class="px-3 py-2 font-medium text-start">
              {{ $t('WORKLOAD.COMPANY') }}
            </th>
            <th
              v-for="mailbox in MAILBOXES"
              :key="mailbox"
              class="px-2 py-2 text-xs font-medium text-center whitespace-nowrap"
            >
              {{ $t(mailboxLabelKey(mailbox)) }}
            </th>
            <th class="px-3 py-2 font-medium text-center">
              {{ $t('WORKLOAD.TOTAL') }}
            </th>
            <th class="px-3 py-2 font-medium text-center">
              {{ $t('WORKLOAD.KPI.UNASSIGNED') }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="company in companies"
            :key="company.id"
            class="border-t cursor-pointer border-n-weak hover:bg-n-alpha-1"
            @click="openCompany(company.id)"
          >
            <td class="px-3 py-2 truncate max-w-64 text-n-slate-12">
              <button
                type="button"
                class="ltr:mr-2 rtl:ml-2 align-middle"
                :class="
                  isPinned(company.id)
                    ? 'text-n-amber-10'
                    : 'text-n-slate-8 hover:text-n-slate-11'
                "
                :title="$t('WORKLOAD.PIN')"
                @click.stop="togglePin(company.id)"
              >
                <span class="i-lucide-star size-4 block" />
              </button>
              {{ company.name }}
            </td>
            <td
              v-for="mailbox in MAILBOXES"
              :key="mailbox"
              class="p-1 text-center"
            >
              <span
                class="inline-flex items-center justify-center w-10 h-7 rounded-md text-xs font-medium"
                :class="cellClass(company.cells[mailbox])"
              >
                {{ company.cells[mailbox] || '·' }}
              </span>
            </td>
            <td class="px-3 py-2 font-semibold text-center text-n-slate-12">
              {{ company.total }}
            </td>
            <td
              class="px-3 py-2 text-center"
              :class="company.unassigned ? 'text-n-ruby-11' : 'text-n-slate-9'"
            >
              {{ company.unassigned }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
