# Creates the email inbox for a mailbox provisioned on the mail server (Hestia),
# using the standard settings validated in production: mail.<domain>, IMAP 993
# over SSL, SMTP 465 over SSL/TLS, login = the address itself.
#
# An inbox is never created without its managed company: the company is found
# by authorized_domain, or created from `company_name` (the legal name the mail
# server operator types when adding the domain), and names the inbox
# (`FACT_<company name>`). With neither, nothing is created and :missing_company
# is returned, so the caller refuses the mailbox instead of leaving it orphaned.
# Team links come from the existing mailbox and channel rules, which run on create.
class Inboxes::ProvisionEmailService
  MAILBOX_PREFIXES = { 'facturacion' => 'FACT' }.freeze

  Result = Struct.new(:status, :inbox, :name, :message, keyword_init: true)

  pattr_initialize [:account!, :email!, :password, :company_name, :dry_run]

  def perform
    return result(:invalid, message: 'email is not a valid address') unless address.match?(URI::MailTo::EMAIL_REGEXP)

    existing = account.email_channels.find_by('lower(email) = ?', address)&.inbox
    return result(:exists, inbox: existing, name: existing.name) if existing&.managed_company_id.present?

    company = account.managed_companies.find_by(authorized_domain: domain)
    if company.nil? && company_name.blank?
      return result(:missing_company, message: "no managed company has authorized_domain #{domain}; send company_name to create it")
    end

    return link_orphan(existing, company) if existing

    name = inbox_name(company&.name || company_name.strip)
    return result(:would_create, name: name) if dry_run
    return result(:invalid, message: 'password is required') if password.blank?

    result(:created, inbox: create_inbox!(company, name), name: name)
  end

  private

  def address
    @address ||= email.to_s.strip.downcase
  end

  def mailbox
    address.split('@').first
  end

  def domain
    address.split('@').last
  end

  def inbox_name(company_label)
    "#{MAILBOX_PREFIXES.fetch(mailbox, mailbox.upcase)}_#{company_label}"
  end

  def create_inbox!(company, name)
    ActiveRecord::Base.transaction do
      company ||= create_company!
      channel = account.email_channels.create!(channel_attributes)
      account.inboxes.create!(name: name, channel: channel, managed_company: company)
    end
  end

  # An inbox created before its company existed gets attached instead of reported
  # as existing, so assigning a legal name to an old domain leaves no orphans.
  # Updating managed_company_id re-runs the company channel rules; teams already
  # linked to the inbox get the company too, as InboxesController#update does.
  def link_orphan(inbox, company)
    return result(:would_link, inbox: inbox, name: inbox.name) if dry_run

    ActiveRecord::Base.transaction do
      inbox.update!(managed_company: company || create_company!)
      inbox.team_ids.each do |team_id|
        TeamManagedCompany.find_or_create_by!(account_id: inbox.account_id, team_id: team_id, managed_company_id: inbox.managed_company_id)
      end
    end
    result(:linked, inbox: inbox, name: inbox.name)
  end

  def create_company!
    account.managed_companies.create!(name: company_name.strip, authorized_domain: domain, status: :active)
  end

  def channel_attributes
    host = "mail.#{domain}"
    {
      email: address,
      imap_enabled: true, imap_address: host, imap_port: 993, imap_enable_ssl: true,
      imap_login: address, imap_password: password,
      smtp_enabled: true, smtp_address: host, smtp_port: 465, smtp_domain: domain,
      smtp_enable_ssl_tls: true, smtp_enable_starttls_auto: false,
      smtp_openssl_verify_mode: 'none', smtp_authentication: 'login',
      smtp_login: address, smtp_password: password
    }
  end

  def result(status, **attrs)
    Result.new(status: status, **attrs)
  end
end
