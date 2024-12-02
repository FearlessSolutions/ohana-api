module FilterCategoriesHelper

  def fetch_categories
    @categories ||= Category.unarchived
  end

  def main_categories_array
    fetch_categories if @categories.nil?

    @categories.select { |category|
      category.depth == 0
    }.flatten.uniq.map { |category|
      [category.name, category.id]
    }
  end

  def categories_for_select
    fetch_categories if @categories.nil?

    @categories.select { |category|
      category.depth == 0
    }.flatten.uniq.map { |category|
      [category.name, category.name]
    }
  end

  def category_name_by_id(category_id)
    main_categories_array.select{ |x| x[1] == category_id.to_i }.first.first
  end

  def get_category_id_by_name(main_category_selected_name)
    main_categories_array.select{ |x| x[0] == main_category_selected_name }.first.second
  end

  def category_filters_title(category_name)
    "#{category_name} #{t('labels.filters.category_filter_title')}"
  end

  def subcategories_by_category(category_id)
    fetch_categories if @categories.nil?

    @categories.select { |category|
      category.depth == 1 and category.parent_id == category_id.to_i
    }.flatten.uniq.map { |category|
      category.name
    }
  end

  def subcategory_id_by_name(subcategory_name, main_category_id)
    fetch_categories if @categories.nil?
    category = @categories.find { |sub_cat| sub_cat.name == subcategory_name && sub_cat.parent_id == main_category_id }
    category&.id
  end

  def get_subcategories_ids(subcategories, main_category_id)
    return [] if subcategories.blank? || main_category_id.blank?

    subcategories.map do |subcategory|
      id = subcategory_id_by_name(subcategory, main_category_id)
      id.present? ? id : nil
    end.compact
  end


  def accessibility_filters
    [
      {
        :id=>518,
        :depth=>1,
        :taxonomy_id=>"99",
        :name=>"Accessibility",
        :parent_id=>nil,
        :type=>"accessibility",
        :filter=>true,
        :filter_parent=>true,
        :filter_priority=>90
      },
      {
        :id=>519,
        :depth=>2,
        :taxonomy_id=>"99-01",
        :name=>"Interpreter For The Deaf Or TTY",
        :parent_id=>518,
        :type=>"accessibility",
        :filter=>true,
        :filter_parent=>false,
        :filter_priority=>0,
        :query => 'deaf_interpreter'
      },
      {
        :id=>520,
        :depth=>2,
        :taxonomy_id=>"99-02",
        :name=>"Disabled Parking Available",
        :parent_id=>518,
        :type=>"accessibility",
        :filter=>true,
        :filter_parent=>false,
        :filter_priority=>0,
        :query=> 'disabled_parking'
      },
      {
        :id=>521,
        :depth=>2,
        :taxonomy_id=>"99-03",
        :name=>"Ramp Available",
        :parent_id=>518,
        :type=>"accessibility",
        :filter=>true,
        :filter_parent=>false,
        :filter_priority=>0,
         :query=> 'ramp'
      },
      {
        :id=>522,
        :depth=>2,
        :taxonomy_id=>"99-04",
        :name=>"Information In Braille Or Audio Format",
        :parent_id=>518,
        :type=>"accessibility",
        :filter=>true,
        :filter_parent=>false,
        :filter_priority=>0,
        :query=> 'tape_braille'
      },
      {
        :id=>523,
        :depth=>2,
        :taxonomy_id=>"99-05",
        :name=>"Wheelchair Accessible",
        :parent_id=>518,
        :type=>"accessibility",
        :filter=>true,
        :filter_parent=>false,
        :filter_priority=>0,
        :query=> 'wheelchair'
      }]
  end
end
