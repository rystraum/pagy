# frozen_string_literal: true

require_relative '../test_helper'

describe 'pagy/frontend' do
  let(:view) { MockView.new }

  describe '#pagy_nav' do
    it 'renders page 1' do
      pagy = Pagy.new count: 103, page: 1
      _(view.pagy_nav(pagy)).must_rematch
      _(view.pagy_nav(pagy, pagy_id: 'test-nav-id', link_extra: 'link-extra')).must_rematch
    end
    it 'renders page 3' do
      pagy = Pagy.new count: 103, page: 3
      _(view.pagy_nav(pagy)).must_rematch
      _(view.pagy_nav(pagy, pagy_id: 'test-nav-id', link_extra: 'link-extra')).must_rematch
    end
    it 'renders page 6' do
      pagy = Pagy.new count: 103, page: 6
      _(view.pagy_nav(pagy)).must_rematch
      _(view.pagy_nav(pagy, pagy_id: 'test-nav-id', link_extra: 'link-extra')).must_rematch
    end
    it 'renders page 10' do
      pagy = Pagy.new count: 1000, page: 10
      _(view.pagy_nav(pagy)).must_rematch
      _(view.pagy_nav(pagy, pagy_id: 'test-nav-id', link_extra: 'link-extra')).must_rematch
    end
    it 'renders with link_extras' do
      pagy = Pagy.new count: 103, page: 1, link_extra: "X"
      _(view.pagy_nav(pagy)).must_include '?page=2" X  rel'
      _(view.pagy_nav(pagy, link_extra: 'link-extra')).must_include '?page=2" X link-extra rel'
    end
  end

  describe '#pagy_link_proc' do
    it 'renders with extras' do
      pagy = Pagy.new count: 103, page: 1
      _(view.pagy_link_proc(pagy, link_extra: "X").call(1)).must_equal '<a href="/foo?page=1"  X >1</a>'
    end
  end

  describe '#pagy_t' do
    it 'pluralizes' do
      _(view.pagy_t('pagy.nav.prev')).must_equal "&lsaquo;&nbsp;Prev"
      _(view.pagy_t('pagy.item_name', count: 0)).must_equal "items"
      _(view.pagy_t('pagy.item_name', count: 1)).must_equal "item"
      _(view.pagy_t('pagy.item_name', count: 10)).must_equal "items"
    end
    # rubocop:disable Style/FormatStringToken
    it 'interpolates' do
      _(view.pagy_t('pagy.info.no_items', count: 0)).must_equal "No %{item_name} found"
      _(view.pagy_t('pagy.info.single_page', count: 1)).must_equal "Displaying <b>1</b> %{item_name}"
      _(view.pagy_t('pagy.info.single_page', count: 10)).must_equal "Displaying <b>10</b> %{item_name}"
      _(view.pagy_t('pagy.info.multiple_pages', count: 10)).must_equal "Displaying %{item_name} <b>%{from}-%{to}</b> of <b>10</b> in total"
      _(view.pagy_t('pagy.info.multiple_pages', item_name: 'Products', count: 300, from: 101, to: 125)).must_equal "Displaying Products <b>101-125</b> of <b>300</b> in total"
    end
    # rubocop:enable Style/FormatStringToken
    it 'handles missing keys' do
      _(view.pagy_t('pagy.nav.not_here')).must_equal '[translation missing: "pagy.nav.not_here"]'
      _(view.pagy_t('pagy.nav.gap.not_here')).must_equal '[translation missing: "pagy.nav.gap.not_here"]'
    end
  end

  describe "Pagy::I18n" do
    it 'loads custom :locale, :filepath and :pluralize' do
      _(proc{ Pagy::I18n.load(locale: 'xx') }).must_raise Errno::ENOENT
      _(proc{ Pagy::I18n.load(locale: 'xx', filepath: Pagy.root.join('locales', 'en.yml'))}).must_raise Pagy::VariableError
      _(proc{ Pagy::I18n.load(locale: 'en', filepath: Pagy.root.join('locales', 'xx.yml')) }).must_raise Errno::ENOENT
      custom_dictionary = Pagy.root.parent.join('test', 'files', 'custom.yml')
      Pagy::I18n.load(locale: 'custom', filepath: custom_dictionary)
      _(Pagy::I18n.t('custom', 'pagy.nav.prev')).must_equal "&lsaquo;&nbsp;Custom Prev"
      Pagy::I18n.load(locale: 'en', pluralize: ->(_){ 'one' }) # returns always 'one' regardless the count
      _(Pagy::I18n.t(nil, 'pagy.item_name', count: 0)).must_equal "item"
      _(Pagy::I18n.t('en', 'pagy.item_name', count: 0)).must_equal "item"
      _(Pagy::I18n.t('en', 'pagy.item_name', count: 1)).must_equal "item"
      _(Pagy::I18n.t('en', 'pagy.item_name', count: 10)).must_equal "item"
      Pagy::I18n.load(locale: 'en') # reset for other tests
    end
    it 'switches :locale according to @pagy_locale' do
      Pagy::I18n.load({locale: 'de'}, {locale: 'en'}, {locale: 'nl'})
      view.instance_variable_set(:@pagy_locale, 'nl')
      _(view.pagy_t('pagy.item_name', count: 1)).must_equal "stuk"
      view.instance_variable_set(:@pagy_locale, 'en')
      _(view.pagy_t('pagy.item_name', count: 1)).must_equal "item"
      view.instance_variable_set(:@pagy_locale, nil)
      _(view.pagy_t('pagy.item_name', count: 1)).must_equal "Eintrag"
      view.instance_variable_set(:@pagy_locale, 'unknown')
      _(view.pagy_t('pagy.item_name', count: 1)).must_equal "Eintrag" # silently serves the first loaded locale
      Pagy::I18n.load(locale: 'en')                         # reset for other tests
      view.instance_variable_set(:@pagy_locale, nil)      # reset for other tests
    end
  end

  describe '#pagy_info' do
    it 'renders without i18n key' do
      _(view.pagy_info(Pagy.new(count: 0))).must_equal '<span class="pagy-info">No items found</span>'
      _(view.pagy_info(Pagy.new(count: 1))).must_equal '<span class="pagy-info">Displaying <b>1</b> item</span>'
      _(view.pagy_info(Pagy.new(count: 13))).must_equal '<span class="pagy-info">Displaying <b>13</b> items</span>'
      _(view.pagy_info(Pagy.new(count: 100, page: 3))).must_equal '<span class="pagy-info">Displaying items <b>41-60</b> of <b>100</b> in total</span>'
    end
    it 'renders with existing i18n key' do
      Pagy::I18n['en'][0]['pagy.info.product.one']   = ->(_){ 'Product'}
      Pagy::I18n['en'][0]['pagy.info.product.other'] = ->(_){ 'Products'}
      _(view.pagy_info(Pagy.new(count: 0, i18n_key: 'pagy.info.product'))).must_equal '<span class="pagy-info">No Products found</span>'
      _(view.pagy_info(Pagy.new(count: 1, i18n_key: 'pagy.info.product'))).must_equal '<span class="pagy-info">Displaying <b>1</b> Product</span>'
      _(view.pagy_info(Pagy.new(count: 13, i18n_key: 'pagy.info.product'))).must_equal '<span class="pagy-info">Displaying <b>13</b> Products</span>'
      _(view.pagy_info(Pagy.new(count: 100, i18n_key: 'pagy.info.product', page: 3))).must_equal '<span class="pagy-info">Displaying Products <b>41-60</b> of <b>100</b> in total</span>'
      _(view.pagy_info(Pagy.new(count: 0), i18n_key: 'pagy.info.product')).must_equal '<span class="pagy-info">No Products found</span>'
      _(view.pagy_info(Pagy.new(count: 1), i18n_key: 'pagy.info.product')).must_equal '<span class="pagy-info">Displaying <b>1</b> Product</span>'
      _(view.pagy_info(Pagy.new(count: 13), i18n_key: 'pagy.info.product')).must_equal '<span class="pagy-info">Displaying <b>13</b> Products</span>'
      _(view.pagy_info(Pagy.new(count: 100, page: 3), i18n_key: 'pagy.info.product')).must_equal '<span class="pagy-info">Displaying Products <b>41-60</b> of <b>100</b> in total</span>'
      Pagy::I18n.load(locale: 'en') # reset for other tests
    end
    it 'overrides the item_name and set pagy_id' do
      _(view.pagy_info(Pagy.new(count: 0), pagy_id: 'pagy-info', item_name: 'Widgets')).must_equal '<span id="pagy-info" class="pagy-info">No Widgets found</span>'
      _(view.pagy_info(Pagy.new(count: 1), pagy_id: 'pagy-info', item_name: 'Widget')).must_equal '<span id="pagy-info" class="pagy-info">Displaying <b>1</b> Widget</span>'
      _(view.pagy_info(Pagy.new(count: 13), pagy_id: 'pagy-info', item_name: 'Widgets')).must_equal '<span id="pagy-info" class="pagy-info">Displaying <b>13</b> Widgets</span>'
      _(view.pagy_info(Pagy.new(count: 100, page: 3), pagy_id: 'pagy-info', item_name: 'Widgets')).must_equal '<span id="pagy-info" class="pagy-info">Displaying Widgets <b>41-60</b> of <b>100</b> in total</span>'
    end
  end

  describe '#pagy_url_for' do
    it 'renders basic url' do
      pagy = Pagy.new count: 1000, page: 3
      _(view.pagy_url_for(pagy, 5)).must_equal '/foo?page=5'
      _(view.pagy_url_for(pagy, 5, absolute: true)).must_equal 'http://example.com:3000/foo?page=5'
    end
    it 'renders url with params' do
      pagy = Pagy.new count: 1000, page: 3, params: {a: 3, b: 4}
      _(view.pagy_url_for(pagy, 5)).must_equal "/foo?page=5&a=3&b=4"
      _(view.pagy_url_for(pagy, 5, absolute: true)).must_equal "http://example.com:3000/foo?page=5&a=3&b=4"
    end
    it 'renders url with fragment' do
      pagy = Pagy.new count: 1000, page: 3, fragment: '#fragment'
      _(view.pagy_url_for(pagy, 6)).must_equal '/foo?page=6#fragment'
      _(view.pagy_url_for(pagy, 6, absolute: true)).must_equal 'http://example.com:3000/foo?page=6#fragment'
    end
    it 'renders url with params and fragment' do
      pagy = Pagy.new count: 1000, page: 3, params: {a: 3, b: 4}, fragment: '#fragment'
      _(view.pagy_url_for(pagy, 5)).must_equal "/foo?page=5&a=3&b=4#fragment"
      _(view.pagy_url_for(pagy, 5, absolute: true)).must_equal "http://example.com:3000/foo?page=5&a=3&b=4#fragment"
    end
  end

  describe '#pagy_get_params' do
    it 'overrides params' do
      overridden = MockView::Overridden.new
      pagy = Pagy.new count: 1000, page: 3, params: {a: 3, b: 4}, fragment: '#fragment'
      _(overridden.pagy_url_for(pagy, 5)).must_equal "/foo?page=5&b=4&k=k#fragment"
    end
  end

end
