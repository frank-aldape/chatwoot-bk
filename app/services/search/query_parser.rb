# Splits a search box query into free text and `key:value` filters, so
# `buzón:facturacion empresa:"consorcio platinum" factura 4471` searches
# "factura 4471" inside the Facturación mailbox of that company.
#
# Keys and values ignore case and accents. Repeating a key ORs its values;
# different keys AND together. Unknown keys stay part of the text.
class Search::QueryParser
  KEYS = {
    'buzon' => :mailbox, 'mailbox' => :mailbox,
    'empresa' => :company, 'company' => :company,
    'asignado' => :assignee, 'assignee' => :assignee,
    'equipo' => :team, 'team' => :team,
    'etiqueta' => :label, 'label' => :label,
    'estado' => :status, 'status' => :status,
    'prioridad' => :priority, 'priority' => :priority
  }.freeze

  TOKEN = /(?<![^\s])([\p{L}]+):(?:"([^"]*)"|(\S+))/

  Result = Struct.new(:text, :filters, keyword_init: true)

  def self.normalize(value)
    ActiveSupport::Inflector.transliterate(value.to_s).downcase.strip
  end

  def self.parse(query)
    filters = Hash.new { |hash, key| hash[key] = [] }
    text = query.to_s.gsub(TOKEN) do |token|
      key = KEYS[normalize(Regexp.last_match(1))]
      value = normalize(Regexp.last_match(2) || Regexp.last_match(3))
      next token if key.nil? || value.blank?

      filters[key] << value
      ' '
    end
    Result.new(text: text.squish, filters: filters.transform_values(&:uniq).to_h)
  end
end
