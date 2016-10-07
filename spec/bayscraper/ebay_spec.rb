require 'spec_helper'

module Bayscraper
  describe Ebay do
    describe '#price_order' do
      context 'there are results' do
        let(:search_terms) { 'zvex instant junky -power' }

        subject do
          VCR.use_cassette('ebay_api_results') do
            Bayscraper::Ebay.new(search_terms).price_order 
          end
        end

        it 'returns an array of hashes' do
          expect(subject.class).to eql(Array)

          subject.each do |sub|
            expect(sub.class).to eql(Hash)
          end
        end

        it 'has item information in each hash' do
          expect(subject[0]).to include(
            :title,
            :total_price,
            :link,
            :image,
            :end_time,
            :current_price,
            :shipping_cost
          )
        end

        it 'provides them in price order, including postage' do
          subject[0..-2].each_with_index do |sub, index|
            expect(sub[:total_price] - subject[index + 1][:total_price]).
              to be <= 0
          end
        end
      end

      context '' do
        let(:search_terms_no_results) { 'Barbie & Ken\'s Underwater Toaster' }

        subject do
          VCR.use_cassette('ebay_api_no_results') do
            Bayscraper::Ebay.new(search_terms_no_results).price_order 
          end
        end

        it 'returns an empty array' do
          expect(subject.class).to eql(Array)

          expect(subject).to be_empty
        end
      end
    end
  end
end
