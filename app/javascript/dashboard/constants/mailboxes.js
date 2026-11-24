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
