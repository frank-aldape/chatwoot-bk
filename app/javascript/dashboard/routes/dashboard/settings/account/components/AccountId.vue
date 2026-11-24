<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';

import SectionLayout from './SectionLayout.vue';
import CodeBlock from 'dashboard/components-next/code/CodeBlock.vue';

const { t } = useI18n();
const { currentAccount } = useAccount();

const getAccountId = computed(() => currentAccount.value.id.toString());
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.ACCOUNT_ID.NOTE')"
    with-border
  >
    <CodeBlock :script="getAccountId" />
  </SectionLayout>
</template>
