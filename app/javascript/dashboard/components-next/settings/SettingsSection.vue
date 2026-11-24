<script setup>
// Settings page section: title and description on the left, controls on the
// right. Replaces the legacy dashboard/components/SettingsSection.vue with the
// same props, so migrating a screen only changes the import.
defineProps({
  title: { type: String, default: '' },
  subTitle: { type: String, default: '' },
  note: { type: String, default: '' },
  showBorder: { type: Boolean, default: true },
});
</script>

<template>
  <section
    class="w-full py-8"
    :class="{ 'border-b border-solid border-n-weak': showBorder }"
  >
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-8">
      <div class="flex flex-col gap-2 col-span-2">
        <h3 v-if="title" class="m-0 text-base font-medium text-n-slate-12">
          {{ title }}
        </h3>
        <p
          v-if="subTitle || $slots.subTitle"
          class="m-0 text-sm leading-5 text-n-slate-11"
        >
          <slot name="subTitle">{{ subTitle }}</slot>
        </p>
        <p v-if="note" class="m-0 text-sm leading-5 text-n-slate-11">
          <span class="font-semibold text-n-slate-12">
            {{ $t('INBOX_MGMT.NOTE') }}
          </span>
          {{ note }}
        </p>
      </div>
      <div class="col-span-6 xl:col-span-5">
        <slot />
      </div>
    </div>
  </section>
</template>
