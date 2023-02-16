# frozen_string_literal: true

# https://github.com/thoughtbot/factory_bot/issues/1480#issuecomment-793171230
def fake_translation(value = nil, unique: false)
  def_value = value || 'Sample Value'

  I18n.available_locales.map do |loc|
    [loc, unique ? "#{def_value} #{loc}" : def_value]
  end.to_h
end
