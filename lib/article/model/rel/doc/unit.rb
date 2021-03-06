# encoding: utf-8
module Article::Model::Rel::Doc::Unit
  extend ActiveSupport::Concern

  included do
    scope :unit_is, ->(unit) {
      return all if unit.blank?
      unit = [unit] unless unit.class == Array
      unit.each do |c|
        unit += c.public_children if c.level_no == 2
      end
      unit = unit.uniq

      rel = join_creator
      rel.where(Sys::Creator.arel_table[:group_id].in(unit))
    }
  end

  def date_and_unit
    separator = %(<span class="separator">　</span>)
    values = []
    values << %(<span class="date">#{published_at.strftime('%Y年%-m月%-d日')}</span>) if published_at
    values << %(<span class="unit">#{ERB::Util.html_escape(creator.group.name)}</span>) if creator && creator.group
    %(<span class="attributes">（#{values.join(separator)}）</span>).html_safe
  end

  def categories_and_unit
    cate = []
    category_items.each { |c| cate << c.title }
    separator = %(<span class="separator">　</span>)
    values = []
    values << %(<span class="category">#{ERB::Util.html_escape(cate.join('，'))}</span>) unless cate.empty?
    values << %(<span class="unit">#{ERB::Util.html_escape(creator.group.name)}</span>) if creator && creator.group
    %(<span class="attributes">（#{values.join(separator)}）</span>).html_safe
  end

  def unit_title
    attr = ' '
    if @u = unit
      attr = %(<span class="unit">#{ERB::Util.html_escape(@u.title)}</span>)
    end
    %(<span class="attributes">（#{attr}）</span>).html_safe
  end

  def unit
    return nil unless creator
    return nil if creator.group_id.blank?
    Article::Unit.find_by(id: creator.group_id)
  end
end
