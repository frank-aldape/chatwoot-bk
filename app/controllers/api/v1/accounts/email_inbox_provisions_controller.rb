# Called by the mail server (Hestia) when a mailbox is created, so its inbox
# appears in Chatwoot without manual setup. Idempotent: an existing inbox is
# reported, not duplicated. Requires an administrator API token.
class Api::V1::Accounts::EmailInboxProvisionsController < Api::V1::Accounts::BaseController
  HTTP_STATUS = { created: :created, linked: :ok, exists: :ok, would_create: :ok, would_link: :ok,
                  missing_company: :unprocessable_entity, invalid: :unprocessable_entity }.freeze

  def create
    authorize(Inbox, :create?)

    result = Inboxes::ProvisionEmailService.new(
      account: Current.account,
      email: params.require(:email),
      password: params[:password],
      company_name: params[:company_name],
      dry_run: ActiveModel::Type::Boolean.new.cast(params[:dry_run]),
      settings: mail_server_settings
    ).perform

    render json: { status: result.status, inbox_id: result.inbox&.id, name: result.name, message: result.message },
           status: HTTP_STATUS.fetch(result.status)
  rescue ActiveRecord::RecordInvalid => e
    render json: { status: :invalid, message: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  private

  # IMAP/SMTP server, ports and encryption as configured on the mail server.
  def mail_server_settings
    keys = Inboxes::ProvisionEmailService::SETTING_KEYS
    params.slice(*keys).permit(*keys).to_h
  end
end
