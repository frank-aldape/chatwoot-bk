<script setup>
// One-click prompt to turn on browser push in this browser. Hidden once the
// browser is subscribed, the permission is blocked, or the agent dismisses it.
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Banner from 'dashboard/components/ui/Banner.vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import {
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from 'dashboard/helper/pushHelper';

const { t } = useI18n();
const shouldShowBanner = ref(false);

const canPrompt =
  window.chatwootConfig.vapidPublicKey &&
  'Notification' in window &&
  Notification.permission !== 'denied' &&
  !LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PUSH_PROMPT);

if (canPrompt) {
  verifyServiceWorkerExistence(registration =>
    registration.pushManager.getSubscription().then(subscription => {
      shouldShowBanner.value = !subscription;
    })
  );
}

const enablePush = () => {
  requestPushPermissions({
    onSuccess: () => {
      shouldShowBanner.value = false;
    },
  });
};

const dismiss = () => {
  LocalStorage.set(LOCAL_STORAGE_KEYS.DISMISSED_PUSH_PROMPT, true);
  shouldShowBanner.value = false;
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="primary"
    :banner-message="t('APP_GLOBAL.PUSH_PROMPT.MESSAGE')"
    :action-button-label="t('APP_GLOBAL.PUSH_PROMPT.ENABLE')"
    action-button-icon="i-lucide-bell-ring"
    has-action-button
    has-close-button
    @primary-action="enablePush"
    @close="dismiss"
  />
</template>
