// Base mailbox aliases every company domain gets, in this fixed order.
export const MAILBOXES = [
  'facturacion',
  'ventas',
  'compras',
  'atencion',
  'contacto',
  'administracion',
  'operaciones',
  'contabilidad',
  'sistemas',
  'no-reply',
];

export const mailboxLabelKey = mailbox =>
  `SIDEBAR.MAILBOX_NAMES.${mailbox.toUpperCase().replace('-', '_')}`;

// Color identity per mailbox, shared by the sidebar dot and the chips.
const MAILBOX_COLORS = {
  facturacion: { chip: 'bg-n-teal-3 text-n-teal-11', dot: 'bg-n-teal-9' },
  ventas: { chip: 'bg-n-blue-3 text-n-blue-11', dot: 'bg-n-blue-9' },
  compras: { chip: 'bg-n-amber-3 text-n-amber-11', dot: 'bg-n-amber-9' },
  atencion: { chip: 'bg-n-iris-3 text-n-iris-11', dot: 'bg-n-iris-9' },
  contacto: { chip: 'bg-n-ruby-3 text-n-ruby-11', dot: 'bg-n-ruby-9' },
};
const NEUTRAL_COLORS = {
  chip: 'bg-n-alpha-2 text-n-slate-11',
  dot: 'bg-n-slate-8',
};

export const mailboxColors = mailbox =>
  MAILBOX_COLORS[mailbox] || NEUTRAL_COLORS;

// facturacion@empresa.com → 'facturacion'; '' for non-base addresses.
export const mailboxOfEmail = email => {
  const local = (email || '').split('@')[0].toLowerCase();
  return MAILBOXES.includes(local) ? local : '';
};
