class Email::BaseBuilder
  pattr_initialize [:inbox!]

  # The header templates render "<name> <email>". Names with commas (common in
  # company names) must be quoted, or the header parses as two addresses and
  # the SMTP server rejects the envelope sender with a syntax error.
  def self.quote_display_name(header, email)
    address = Mail::Address.new(email)
    address.display_name = header.delete_suffix("<#{email}>").strip
    address.to_s
  end

  private

  def channel
    @channel ||= inbox.channel
  end

  def account
    @account ||= inbox.account
  end

  def conversation
    @conversation ||= message.conversation
  end

  # Always "<business_name> <email>": agent names never appear in the From header.
  def sender_name(sender_email)
    header = I18n.t('conversations.reply.email.header.professional_name', business_name: business_name, from_email: sender_email)
    self.class.quote_display_name(header, sender_email)
  end

  def business_name
    inbox.business_name || inbox.sanitized_name
  end

  def account_support_email
    # Parse the email to ensure it's in the correct format, the user
    # can save it in the format "Name <email@domain.com>"
    parse_email(account.support_email)
  end

  def parse_email(email_string)
    Mail::Address.new(email_string).address
  end
end
