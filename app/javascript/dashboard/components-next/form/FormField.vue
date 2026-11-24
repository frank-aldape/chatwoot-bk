<script setup>
// The one form field wrapper: label + any control + help or error text. For a
// plain text box prefer components-next Input, which already includes these.
defineProps({
  label: { type: String, default: '' },
  // id of the control inside, so the label focuses it
  for: { type: String, default: '' },
  help: { type: String, default: '' },
  error: { type: String, default: '' },
});
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <label
      v-if="label"
      :for="$props.for || undefined"
      class="m-0 text-sm font-medium text-n-slate-12"
    >
      {{ label }}
    </label>
    <slot />
    <p v-if="error" class="m-0 text-xs text-n-ruby-11" role="alert">
      {{ error }}
    </p>
    <p v-else-if="help" class="m-0 text-xs text-n-slate-11">
      {{ help }}
    </p>
  </div>
</template>
