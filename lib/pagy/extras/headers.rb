# See the Pagy documentation: https://ddnexus.github.io/pagy/extras/headers
# frozen_string_literal: true

class Pagy
  # Add specialized backend methods to add pagination response headers
  module Backend
    private

    VARS[:headers] = { page: 'Current-Page', items: 'Page-Items', count: 'Total-Count', pages: 'Total-Pages' }

    include Helpers

    def pagy_headers_merge(pagy)
      response.headers.merge!(pagy_headers(pagy))
    end

    def pagy_headers(pagy)
      pagy_headers_hash(pagy).tap do |hash|
        hash['Link'] = hash['Link'].map{|rel, link| %(<#{link}>; rel="#{rel}")}.join(', ')
      end
    end

    def pagy_headers_hash(pagy)
      countless = defined?(Pagy::Countless) && pagy.is_a?(Pagy::Countless)
      rels = { 'first' => 1, 'prev' => pagy.prev, 'next' => pagy.next }
      rels['last'] = pagy.last unless countless
      url_str = pagy_url_for(pagy, PAGE_PLACEHOLDER, absolute: true)
      hash    = { 'Link' => rels.filter_map do |rel, num|
                              next unless num
                              [ rel, url_str.sub(PAGE_PLACEHOLDER, num.to_s) ]
                            end.to_h }
      headers = pagy.vars[:headers]
      hash[headers[:page]]  = pagy.page.to_s         if headers[:page]
      hash[headers[:items]] = pagy.vars[:items].to_s if headers[:items]
      unless countless
        hash[headers[:pages]] = pagy.pages.to_s if headers[:pages]
        hash[headers[:count]] = pagy.count.to_s if headers[:count]
      end
      hash
    end

  end
end
