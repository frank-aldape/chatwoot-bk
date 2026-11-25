<script setup>
// "Carga por empresa y buzón": open conversations as a company x mailbox
// heatmap. Each cell opens that company narrowed to that mailbox.
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import ConversationApi from 'dashboard/api/inbox/conversation';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import {
  MAILBOXES,
  mailboxColors,
  mailboxLabelKey,
} from 'dashboard/constants/mailboxes';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const route = useRoute();
const inboxes = useMapGetter('inboxes/getInboxes');

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
const onlyPending = ref(true);

ConversationApi.loadMatrix()
  .then(({ data }) => {
    rows.value = data;
  })
  .finally(() => {
    isLoading.value = false;
  });

// Every company the user can see (from their inboxes), with its open counts.
const allCompanies = computed(() => {
  const byId = new Map();
  inboxes.value.forEach(({ managed_company: company }) => {
    if (company?.id) {
      byId.set(company.id, {
        id: company.id,
        name: company.name,
        total: 0,
        unassigned: 0,
        cells: {},
      });
    }
  });
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
  return [...byId.values()];
});

const pendingCount = computed(
  () => allCompanies.value.filter(company => company.total).length
);

const companies = computed(() => {
  const query = search.value.trim().toLowerCase();
  return allCompanies.value
    .filter(company => !onlyPending.value || company.total)
    .filter(company => company.name.toLowerCase().includes(query))
    .sort((a, b) => b.total - a.total || a.name.localeCompare(b.name));
});

const mailboxTotals = computed(() =>
  rows.value.reduce((totals, row) => {
    totals[row.mailbox] = (totals[row.mailbox] || 0) + row.count;
    return totals;
  }, {})
);

const busiestMailbox = computed(
  () => Object.entries(mailboxTotals.value).sort((a, b) => b[1] - a[1])[0]
);

const kpis = computed(() => {
  const [mailbox, mailboxOpen] = busiestMailbox.value || [];
  return [
    {
      key: 'COMPANIES',
      value: pendingCount.value,
      hint: t('WORKLOAD.KPI_HINT.COMPANIES', {
        count: allCompanies.value.length,
      }),
    },
    {
      key: 'OPEN',
      value: rows.value.reduce((sum, row) => sum + row.count, 0),
      hint: t('WORKLOAD.KPI_HINT.OPEN'),
    },
    {
      key: 'UNASSIGNED',
      value: rows.value.reduce((sum, row) => sum + row.unassigned, 0),
      hint: t('WORKLOAD.KPI_HINT.UNASSIGNED'),
      isAlert: true,
    },
    {
      key: 'BUSIEST_MAILBOX',
      value: mailbox ? t(mailboxLabelKey(mailbox)) : '—',
      hint: mailbox
        ? t('WORKLOAD.KPI_HINT.BUSIEST_MAILBOX', { count: mailboxOpen })
        : '',
    },
  ];
});

const footer = computed(() =>
  onlyPending.value
    ? t('WORKLOAD.FOOTER_PENDING', {
        shown: companies.value.length,
        hidden: allCompanies.value.length - pendingCount.value,
      })
    : t('WORKLOAD.FOOTER_ALL', { shown: companies.value.length })
);

const cellClass = count => {
  if (!count) return 'text-n-slate-9 font-medium';
  if (count <= 2) {
    return 'bg-n-blue-2 text-n-blue-12 outline outline-1 outline-n-blue-5';
  }
  if (count <= 5) return 'bg-n-blue-5 text-n-blue-12';
  return 'bg-n-blue-9 text-white';
};

const companyRoute = (companyId, mailbox) => ({
  name: 'managed_company_conversations',
  params: { accountId: route.params.accountId, managedCompanyId: companyId },
  query: mailbox ? { mailbox } : {},
});
const homeRoute = computed(() => ({
  name: 'home',
  params: { accountId: route.params.accountId },
}));
</script>

<template>
  <div class="w-full h-full overflow-auto bg-n-background">
    <div class="flex flex-col gap-5 max-w-7xl mx-auto px-6 py-7">
      <div class="flex flex-col gap-1">
        <router-link
          :to="homeRoute"
          class="text-sm font-semibold text-n-blue-text hover:underline"
        >
          {{ $t('WORKLOAD.BACK') }}
        </router-link>
        <h1 class="text-2xl font-bold text-n-slate-12">
          {{ $t('WORKLOAD.TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ $t('WORKLOAD.SUBTITLE', { count: allCompanies.length }) }}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-3 md:grid-cols-4">
        <div
          v-for="kpi in kpis"
          :key="kpi.key"
          class="flex flex-col gap-1.5 min-w-0 rounded-xl p-4 bg-n-solid-2 outline outline-1 outline-n-weak"
        >
          <p class="text-sm font-semibold text-n-slate-11">
            {{ $t(`WORKLOAD.KPI.${kpi.key}`) }}
          </p>
          <p
            class="text-3xl font-bold truncate"
            :class="kpi.isAlert ? 'text-n-ruby-11' : 'text-n-slate-12'"
          >
            {{ kpi.value }}
          </p>
          <p class="text-xs text-n-slate-11 truncate">{{ kpi.hint }}</p>
        </div>
      </div>

      <div
        class="flex flex-col rounded-2xl bg-n-solid-2 outline outline-1 outline-n-weak"
      >
        <div
          class="flex flex-wrap items-center gap-2.5 px-4 py-3.5 border-b border-n-weak"
        >
          <label
            class="flex flex-1 items-center gap-2 min-w-[14rem] h-10 px-3 rounded-lg outline outline-1 outline-n-weak focus-within:outline-n-brand text-n-slate-10"
          >
            <span class="i-lucide-search size-4 flex-shrink-0" />
            <input
              v-model="search"
              type="search"
              class="reset-base flex-1 min-w-0 h-auto p-0 border-0 bg-transparent text-sm text-n-slate-12 outline-none placeholder:text-n-slate-10 focus:ring-0"
              :placeholder="
                $t('WORKLOAD.SEARCH', { count: allCompanies.length })
              "
            />
          </label>
          <Button
            :label="$t('WORKLOAD.ONLY_PENDING')"
            :icon="onlyPending ? 'i-lucide-circle-check' : 'i-lucide-circle'"
            :color="onlyPending ? 'blue' : 'slate'"
            variant="faded"
            :aria-pressed="onlyPending"
            @click="onlyPending = !onlyPending"
          />
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
        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm border-collapse min-w-[56rem]">
            <thead>
              <tr class="text-xs font-bold text-n-slate-11">
                <th class="px-4 py-3 border-b text-start border-n-weak">
                  {{ $t('WORKLOAD.COMPANY') }}
                </th>
                <th
                  v-for="mailbox in MAILBOXES"
                  :key="mailbox"
                  class="px-2 py-3 text-center border-b border-n-weak whitespace-nowrap"
                >
                  <span class="inline-flex items-center gap-1.5">
                    <span
                      class="size-2 rounded-full"
                      :class="mailboxColors(mailbox).dot"
                    />
                    {{ $t(mailboxLabelKey(mailbox)) }}
                  </span>
                </th>
                <th class="px-4 py-3 border-b text-end border-n-weak">
                  {{ $t('WORKLOAD.TOTAL') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="company in companies"
                :key="company.id"
                class="hover:bg-n-alpha-1"
              >
                <th
                  class="px-4 py-2 font-semibold border-b text-start border-n-weak whitespace-nowrap"
                >
                  <span class="inline-flex items-center gap-2 max-w-[18rem]">
                    <button
                      type="button"
                      :class="
                        isPinned(company.id)
                          ? 'text-n-amber-10'
                          : 'text-n-slate-8 hover:text-n-slate-11'
                      "
                      :title="$t('WORKLOAD.PIN')"
                      :aria-label="$t('WORKLOAD.PIN')"
                      :aria-pressed="isPinned(company.id)"
                      @click="togglePin(company.id)"
                    >
                      <span class="i-lucide-star size-3.5 block" />
                    </button>
                    <router-link
                      :to="companyRoute(company.id)"
                      class="truncate text-n-slate-12 hover:underline"
                    >
                      {{ company.name }}
                    </router-link>
                  </span>
                </th>
                <td
                  v-for="mailbox in MAILBOXES"
                  :key="mailbox"
                  class="px-2 py-1.5 text-center border-b border-n-weak"
                >
                  <router-link
                    v-if="company.cells[mailbox]"
                    :to="companyRoute(company.id, mailbox)"
                    class="inline-flex items-center justify-center min-w-[2.75rem] h-8 rounded-lg text-sm font-bold"
                    :class="cellClass(company.cells[mailbox])"
                    :aria-label="
                      $t('WORKLOAD.CELL_LABEL', {
                        company: company.name,
                        mailbox: $t(mailboxLabelKey(mailbox)),
                        count: company.cells[mailbox],
                      })
                    "
                  >
                    {{ company.cells[mailbox] }}
                  </router-link>
                  <span v-else :class="cellClass(0)">
                    {{ $t('WORKLOAD.EMPTY_CELL') }}
                  </span>
                </td>
                <td
                  class="px-4 py-2 border-b text-end border-n-weak whitespace-nowrap"
                >
                  <span class="text-sm font-bold text-n-slate-12">
                    {{ company.total }}
                  </span>
                  <span
                    v-if="company.unassigned"
                    class="block text-xxs font-semibold text-n-ruby-11"
                  >
                    {{
                      $t('WORKLOAD.UNASSIGNED_COUNT', {
                        count: company.unassigned,
                      })
                    }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p
          v-if="!isLoading"
          class="px-4 py-3 text-sm border-t text-n-slate-11 border-n-weak"
        >
          {{ footer }}
        </p>
      </div>

      <div class="flex flex-wrap items-center gap-4 text-xs text-n-slate-11">
        <span>{{ $t('WORKLOAD.LEGEND.TITLE') }}</span>
        <span class="inline-flex items-center gap-1.5">
          <span class="w-4 h-3.5 rounded" :class="cellClass(1)" />
          {{ $t('WORKLOAD.LEGEND.LOW') }}
        </span>
        <span class="inline-flex items-center gap-1.5">
          <span class="w-4 h-3.5 rounded" :class="cellClass(3)" />
          {{ $t('WORKLOAD.LEGEND.MEDIUM') }}
        </span>
        <span class="inline-flex items-center gap-1.5">
          <span class="w-4 h-3.5 rounded" :class="cellClass(6)" />
          {{ $t('WORKLOAD.LEGEND.HIGH') }}
        </span>
      </div>
    </div>
  </div>
</template>
