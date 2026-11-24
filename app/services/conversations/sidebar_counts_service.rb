# Open-conversation counts for the conversations sidebar: one number per mailbox
# alias (email local part) and per managed company, limited to what the user can see.
class Conversations::SidebarCountsService
  MAILBOX_SQL = "lower(split_part(channel_email.email, '@', 1))".freeze
  CHANNEL_EMAIL_JOIN = "INNER JOIN channel_email ON inboxes.channel_type = 'Channel::Email' AND channel_email.id = inboxes.channel_id".freeze

  pattr_initialize [:user!, :account!]

  def perform
    { mailboxes: mailbox_counts, companies: company_counts }
  end

  private

  def open_conversations
    @open_conversations ||= Conversations::PermissionFilterService.new(account.conversations.open, user, account).perform
  end

  def mailbox_counts
    open_conversations.joins(:inbox).joins(CHANNEL_EMAIL_JOIN).group(Arel.sql(MAILBOX_SQL)).count
  end

  def company_counts
    by_company = open_conversations.joins(inbox: :managed_company).group('managed_companies.id', 'managed_companies.name')
    unassigned = by_company.where(assignee_id: nil).count

    by_company.count.map do |(id, name), count|
      { id: id, name: name, count: count, unassigned: unassigned[[id, name]] || 0 }
    end
  end
end
