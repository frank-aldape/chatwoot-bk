<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import PageHeader from '../SettingsSubPageHeader.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const selectedTeams = ref([]);
const isCreating = ref(false);
const hasSubmitted = ref(false);

const teamList = useMapGetter('teams/getTeams');
const teamOptions = computed(() =>
  teamList.value.map(team => ({ value: team.id, label: team.name }))
);
const selectedTeamIds = computed({
  get: () => selectedTeams.value.map(team => team.id),
  set: ids => {
    selectedTeams.value = teamList.value.filter(team => ids.includes(team.id));
  },
});
const hasError = computed(
  () => hasSubmitted.value && !selectedTeams.value.length
);

// Teams declaring this inbox's mailbox are linked on create; preselect them so
// submitting this step (which replaces the team list) keeps those links.
onMounted(async () => {
  await Promise.all([
    store.dispatch('teams/get'),
    store.dispatch('inboxes/show', route.params.inbox_id),
  ]);
  const inbox = store.getters['inboxes/getInbox'](route.params.inbox_id);
  const linkedIds = inbox.team_ids || [];
  selectedTeams.value = teamList.value.filter(team =>
    linkedIds.includes(team.id)
  );
});

const addTeams = async () => {
  hasSubmitted.value = true;
  if (!selectedTeams.value.length) return;

  isCreating.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: route.params.inbox_id,
      formData: false,
      team_ids: selectedTeams.value.map(team => team.id),
    });
    router.replace({
      name: 'settings_inbox_finish',
      params: { page: 'new', inbox_id: route.params.inbox_id },
    });
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.TEAMS.API_ERROR'));
  }
  isCreating.value = false;
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <form class="flex flex-wrap flex-col mx-0" @submit.prevent="addTeams()">
      <div class="w-full">
        <PageHeader
          :header-title="t('INBOX_MGMT.ADD.TEAMS.TITLE')"
          :header-content="t('INBOX_MGMT.ADD.TEAMS.DESC')"
        />
      </div>
      <div>
        <div class="w-full">
          <label class="block mb-1 text-sm font-medium text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.TEAMS.TITLE') }}
          </label>
          <TagMultiSelectComboBox
            v-model="selectedTeamIds"
            :options="teamOptions"
            :placeholder="t('INBOX_MGMT.ADD.TEAMS.PICK_TEAMS')"
            :has-error="hasError"
            :message="
              hasError ? t('INBOX_MGMT.ADD.TEAMS.VALIDATION_ERROR') : ''
            "
            class="mb-4"
          />
        </div>
        <div class="w-full">
          <NextButton
            type="submit"
            :is-loading="isCreating"
            solid
            blue
            :label="t('INBOX_MGMT.AGENTS.BUTTON_TEXT')"
          />
        </div>
      </div>
    </form>
  </div>
</template>
