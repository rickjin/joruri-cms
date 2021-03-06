# encoding: utf-8
class Bbs::Piece::RecentItem < Cms::Piece
  validate :validate_settings

  def validate_settings
    return if in_settings['list_count'].blank?

    if in_settings['list_count'] !~ /^[0-9]+$/
      errors.add(:base,"#{self.class.human_attribute_name :list_count} #{errors.generate_message(:base, :not_a_number)}")
    end
  end

  def list_types
    [["すべての投稿を表示", 0], ["スレッド投稿を表示", 1], ["レス投稿を表示", 2]]
  end

  def list_type_label
    val = setting_value(:list_type)
    list_types.each do |t|
      return t[0] if t[1].to_s == val
    end
    nil
  end
end
