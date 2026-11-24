# Narrows a conversation scope by the `key:value` filters of Search::QueryParser.
# Each key is one AND condition; the values of a key are ORed. Text matching
# compares lower-cased, accent-stripped strings on both sides.
class Search::ConversationFilters
  STATUSES = {
    'abierta' => 'open', 'abierto' => 'open', 'abiertas' => 'open', 'open' => 'open',
    'resuelta' => 'resolved', 'resuelto' => 'resolved', 'resueltas' => 'resolved', 'resolved' => 'resolved',
    'pendiente' => 'pending', 'pendientes' => 'pending', 'pending' => 'pending',
    'pospuesta' => 'snoozed', 'pospuesto' => 'snoozed', 'pospuestas' => 'snoozed', 'snoozed' => 'snoozed'
  }.freeze

  PRIORITIES = {
    'baja' => 'low', 'low' => 'low', 'media' => 'medium', 'medium' => 'medium',
    'alta' => 'high', 'high' => 'high', 'urgente' => 'urgent', 'urgent' => 'urgent',
    'ninguna' => nil, 'sin' => nil, 'none' => nil
  }.freeze

  ME = %w[yo mi me mio mine].freeze
  NOBODY = %w[ninguno nadie sin none].freeze

  pattr_initialize [:scope!, :filters!, :account!, :user!]

  def perform
    filters.reduce(scope) do |relation, (key, values)|
      send("by_#{key}", relation, values)
    end
  end

  private

  # lower() + translate() mirrors Search::QueryParser.normalize in SQL
  def normalized(column)
    "translate(lower(#{column}), 'áàäâéèëêíìïîóòöôúùüûñç', 'aaaaeeeeiiiioooouuuunc')"
  end

  def like_any(column, values)
    [values.map { "#{normalized(column)} LIKE ?" }.join(' OR '), *values.map { |v| "%#{ActiveRecord::Base.sanitize_sql_like(v)}%" }]
  end

  def by_mailbox(relation, values)
    relation.where(inbox_id: account.inboxes.joins(
      "INNER JOIN channel_email ON inboxes.channel_type = 'Channel::Email' AND channel_email.id = inboxes.channel_id"
    ).where("lower(split_part(channel_email.email, '@', 1)) IN (?)", values).select(:id))
  end

  def by_company(relation, values)
    name_sql, *name_args = like_any('managed_companies.name', values)
    companies = account.managed_companies.where(
      "#{name_sql} OR managed_companies.authorized_domain IN (?)", *name_args, values
    )
    relation.where(inbox_id: account.inboxes.where(managed_company_id: companies.select(:id)).select(:id))
  end

  def by_assignee(relation, values)
    conditions = []
    conditions << relation.where(assignee_id: user.id) if values.intersect?(ME)
    conditions << relation.where(assignee_id: nil) if values.intersect?(NOBODY)
    names = values - ME - NOBODY
    if names.any?
      sql, *args = like_any('users.name', names)
      display_sql, *display_args = like_any('users.display_name', names)
      conditions << relation.where(assignee_id: account.users.where("#{sql} OR #{display_sql}", *args, *display_args).select(:id))
    end
    conditions.reduce(:or)
  end

  def by_team(relation, values)
    relation.where(team_id: account.teams.where(*like_any('teams.name', values)).select(:id))
  end

  def by_label(relation, values)
    labelled = ActsAsTaggableOn::Tagging.joins(:tag)
                                        .where(taggable_type: 'Conversation', context: 'labels')
                                        .where("#{normalized('tags.name')} IN (?)", values)
                                        .select(:taggable_id)
    relation.where(id: labelled)
  end

  def by_status(relation, values)
    relation.where(status: values.filter_map { |v| STATUSES[v] })
  end

  def by_priority(relation, values)
    known = values.select { |v| PRIORITIES.key?(v) }
    return relation.none if known.empty?

    relation.where(priority: known.map { |v| PRIORITIES[v] })
  end
end
