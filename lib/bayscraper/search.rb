require 'nokogiri'

module Bayscraper
  class Search
    attr_reader :keywords, :exclusions, :min_price, :max_price
    private :keywords, :exclusions, :min_price, :max_price

    def initialize(keywords, exclusions: '', min_price: 0, max_price: 999999)
      @keywords = keywords
      @exclusions = exclusions
      @min_price = min_price
      @max_price = max_price
    end

    def self.search(keywords, exclusions: '', min_price: 0, max_price: 999999)
      new(keywords, exclusions, min_price, max_price).search
    end

    def search
      items_within_price_range
    end

    private

    def scraping_success?
      prices.length == postages.length &&
        postages.length == links.length &&
        prices.length > 0
    end

    def cheapest
      items_within_price_range[0]
    end

    def items_within_price_range
      items_sorted.select do |item|
        item[:total_price].between?(min_price, max_price)
      end
    end

    def items_sorted
      items_hashed.sort_by { |hsh| hsh[:total_price] }
    end

    def items_hashed
      items_zipped.map do |item|
        item = {
          title: item[0],
          total_price: item[3],
          price: item[1],
          postage: item[2],
          link: item[4],
          image: item[5]
        }
      end
    end

    def items_zipped
      title.zip(prices, postages, total_prices, links, images)
    end

    def title
      links_raw.map { |l| l.text }
    end

    def prices
      prices_raw.map do |x|
        x.children.text.strip.tr('Â','').split(' ')[0][/\d+\.?\d+/].to_f
      end
    end

    def postages
      postages_raw.map do |p|
        if ['Free', 'not specified'].any? { |postage| p.include?(postage) }
          0
        else
          p.children.text.strip.tr('Â','').split(' ')[1][/\d+\.?\d+/].to_f
        end
      end
    end

    def total_prices
      [prices, postages].transpose.map { |x| x.reduce(:+).round(2) }
    end

    def links
      links_raw.map { |l| l['href'] }
    end

    def images
      images_raw.map { |i| i['src'] }
    end

    def prices_raw
      items.css('li.lvprice span.bold')
    end

    def postages_raw
      items.css('li.lvshipping span.ship')
    end

    def links_raw
      items.css('h3.lvtitle a')
    end

    def images_raw
      items.css('div.pic a img')
    end

    def items
      page.css('div#Results ul#ListViewInner')
    end

    def page
      @page ||= Nokogiri::HTML(open(ebay_url))
    end

    def ebay_url
      "http://www.ebay.co.uk/sch/?_nkw=#{keywords} #{search_exclusions}&_sop=15&_udlo=#{min_price}&_udhi=#{max_price}"
    end

    def search_exclusions
      exclusions.split(' ').map { |e| '-' + e }.join(' ')
    end
  end
end
