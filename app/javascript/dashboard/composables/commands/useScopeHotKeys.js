import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { MAILBOXES, mailboxLabelKey } from 'dashboard/constants/mailboxes';
import {
  ICON_CONVERSATION_DASHBOARD,
  ICON_INBOXES,
} from 'dashboard/helper/commandbar/icons';

// ⌘K entries that jump straight to a mailbox or a managed company view.
export function useScopeHotKeys() {
  const { t } = useI18n();
  const router = useRouter();
  const accountId = useMapGetter('getCurrentAccountId');
  const inboxes = useMapGetter('inboxes/getInboxes');

  const openRoute = path =>
    router.push(frontendURL(`accounts/${accountId.value}/${path}`));

  const mailboxHotKeys = computed(() =>
    MAILBOXES.map(mailbox => ({
      id: `goto_mailbox_${mailbox}`,
      section: t('COMMAND_BAR.SECTIONS.MAILBOXES'),
      title: t(mailboxLabelKey(mailbox)),
      icon: ICON_INBOXES,
      handler: () => openRoute(`mailboxes/${mailbox}`),
    }))
  );

  const companyHotKeys = computed(() => {
    const byId = new Map();
    inboxes.value.forEach(({ managed_company: company }) => {
      if (company?.id) byId.set(company.id, company);
    });
    return [...byId.values()].map(company => ({
      id: `goto_company_${company.id}`,
      section: t('COMMAND_BAR.SECTIONS.COMPANIES'),
      title: company.name,
      icon: ICON_CONVERSATION_DASHBOARD,
      handler: () => openRoute(`managed_companies/${company.id}`),
    }));
  });

  const scopeHotKeys = computed(() => [
    {
      id: 'goto_workload',
      section: t('COMMAND_BAR.SECTIONS.COMPANIES'),
      title: t('WORKLOAD.TITLE'),
      icon: ICON_CONVERSATION_DASHBOARD,
      handler: () => openRoute('workload'),
    },
    ...mailboxHotKeys.value,
    ...companyHotKeys.value,
  ]);

  return { scopeHotKeys };
}
