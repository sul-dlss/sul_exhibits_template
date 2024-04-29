# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'indexing integration test', type: :feature, vcr: true do
  subject(:dor_harvester) { DorHarvester.new(druid_list: druid, exhibit:) }

  let(:exhibit) { FactoryBot.create(:exhibit) }
  let(:rsolr) { instance_double(RSolr) }
  let(:rsolr_client) { instance_double(RSolr::Client) }

  before do
    allow(RSolr).to receive(:connect).and_return(rsolr_client)
    allow(rsolr_client).to receive(:update)
    allow(rsolr_client).to receive(:commit)

    stub_request(:post, /update/)
    %w(xf680rd3068 dx969tv9730 rk684yq9989 ms016pb9280 cf386wt1778 cc842mn9348 kh392jb5994 ws947mh3822 gh795jd5965 hm136qv0310).each do |fixture|
      stub_request(:get, "https://purl.stanford.edu/#{fixture}.xml").to_return(
        body: File.new(File.join(FIXTURES_PATH, "#{fixture}.xml")), status: 200
      )
    end
  end

  context 'regular image item' do
    let(:druid) { 'xf680rd3068' }

    it 'can write the document to solr' do
      dor_harvester.reindex
    end

    context 'to_solr' do
      subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

      it 'has a doc id' do
        expect(document[:id]).to eq druid
        expect(document[:druid]).to eq druid
      end

      it 'has the gdor data' do
        expect(document).to include :modsxml, :url_fulltext, :modsxml_tsi
      end

      it 'has the published date for the resource' do
        expect(document).to include last_updated: '2017-04-26T16:25:02Z'
      end

      it 'has potentially useless fields inherited from gdor indexer' do
        expect(document).to include display_type: 'image'
      end

      it 'has a iiif manifest url' do
        expect(document).to include iiif_manifest_url_ssi: 'https://purl.stanford.edu/xf680rd3068/iiif/manifest'
      end

      it 'has content metadata fields' do
        expect(document).to include content_metadata_type_ssim: ['image'],
                                    content_metadata_first_image_file_name_ssm: ['xf680rd3068_00_0001'],
                                    content_metadata_first_image_width_ssm: ['1794'],
                                    content_metadata_first_image_height_ssm: ['2627'],
                                    content_metadata_image_iiif_info_ssm: %w(https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0001/info.json https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0002/info.json),
                                    thumbnail_square_url_ssm: ['https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0001/square/100,100/0/default.jpg', 'https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0002/square/100,100/0/default.jpg'],
                                    thumbnail_url_ssm: ['https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0001/full/!400,400/0/default.jpg', 'https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0002/full/!400,400/0/default.jpg'],
                                    large_image_url_ssm: ['https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0001/full/!1000,1000/0/default.jpg', 'https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0002/full/!1000,1000/0/default.jpg'],
                                    full_image_url_ssm: ['https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0001/full/!3000,3000/0/default.jpg', 'https://stacks.stanford.edu/image/iiif/xf680rd3068%2Fxf680rd3068_00_0002/full/!3000,3000/0/default.jpg']
      end

      it 'has MODS title fields' do
        expect(document).to include title_245_search: 'Latin glossary : small manuscript fragment on vellum.',
                                    title_245a_display: 'Latin glossary : small manuscript fragment on vellum',
                                    title_245a_search: 'Latin glossary : small manuscript fragment on vellum',
                                    title_display: 'Latin glossary : small manuscript fragment on vellum',
                                    title_sort: 'Latin glossary small manuscript fragment on vellum'
      end

      it 'has MODS author fields' do
        expect(document).to include author_sort: "\u{10FFFF} Latin glossary  small manuscript fragment on vellum"
      end

      it 'has MODS origin info fields' do
        expect(document).to include imprint_display: 'France?, [1200 - 1299?] 13th century',
                                    pub_year_isi: 1200,
                                    pub_year_no_approx_isi: 1200,
                                    pub_year_w_approx_isi: 1200,
                                    pub_year_tisim: (1200..1299).to_a,
                                    place_created_ssim: ['France?'],
                                    date_ssim: ['13th century', '[1200 - 1299?]']
      end

      it 'has other metadata fields' do
        expect(document).to include general_notes_ssim: [
                                      'Lower portion of vellum leaf, removed from a binding.',
                                      'Script: professional gotica textualis, 2 columns, with a fair amount of abbreviations.'
                                    ],
                                    topic_search: ['Manuscripts, Latin (Medieval and modern)'],
                                    geographic_search: ['France'],
                                    subject_all_search: ['Manuscripts, Latin (Medieval and modern)', 'France'],
                                    topic_facet: ['Manuscripts, Latin (Medieval and modern)'],
                                    geographic_facet: ['France'],
                                    format_main_ssim: ['Archive/Manuscript'],
                                    language: ['Latin'],
                                    physical: ['1 fragment, 96 x 151 mm.'],
                                    summary_search: [start_with('Unidentified Latin vocabulary')],
                                    pub_search: ['fr', 'France?']
      end

      it 'has spotlight data' do
        expect(document).to include :spotlight_resource_id_ssim, :spotlight_resource_type_ssim
      end
    end
  end

  context 'feigenbaum item' do
    subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

    let(:druid) { 'rk684yq9989' }

    before do
      stub_request(:get, 'https://stacks.stanford.edu/file/rk684yq9989/rk684yq9989.txt').to_return(body: 'full text', status: 200)
    end

    it 'has collection information' do
      expect(document).to include collection: ['ms016pb9280'],
                                  collection_with_title: ['ms016pb9280-|-Edward A. Feigenbaum papers, 1950-2007 (inclusive)'],
                                  collection_titles_ssim: ['Edward A. Feigenbaum papers, 1950-2007 (inclusive)']
    end

    it 'has feigenbaum-specific fields' do
      expect(document).to include box_ssi: '1',
                                  folder_ssi: '6',
                                  folder_name_ssi: 'SUN Write-ups and View Graphs',
                                  location_ssi: 'Call Number: SC0340, Accession: 1986-052, Box: 1, Folder: 6',
                                  series_ssi: '1986-052',
                                  donor_tags_ssim: ['Computer Science Department', 'SUN']
    end

    it 'indexes full text content' do
      expect(document).to include full_text_tesimv: ['full text']
    end

    it 'has the correct date information (no blank values)' do
      expect(document).to include date_ssim: ['March 30, 1980']
    end
  end

  context 'an item with ALTO OCR' do
    subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

    let(:druid) { 'cc842mn9348' }

    before do
      fixture_file = File.new(File.join(FIXTURES_PATH, 'cc842mn9348_ocr_1.xml'))
      stub_request(
        :get,
        'https://stacks.stanford.edu/file/cc842mn9348/EastTimor_CE-SPSC_Final_Decisions_2001_04b-2001_Sabino_Gouveia_Leite_Judgment_0001.xml'
      ).to_return(body: fixture_file, status: 200)
    end

    it 'indexes all strings from the ALTO files into the full text field' do
      fulltext = document[:full_text_tesimv]
      expect(fulltext).to be_a Array
      expect(fulltext.length).to eq 1
      expect(fulltext.first).to start_with 'INTRODUCTION 1 The trial of'
      expect(fulltext.first).to end_with 'rendering of the decision.'
    end
  end

  context 'parker item' do
    subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

    let(:druid) { 'cf386wt1778' }

    it 'has parker-specific fields' do
      expect(document).to include dimensions_ssim: ['300 mm Height', '215 mm Width', '12 x 8.7 in Dimensions'],
                                  incipit_tesim: ['In illo tempore maria magdalene et maria iacobi et solomae'],
                                  manuscript_number_tesim: ['MS 69'],
                                  toc_search: ['Homiliae XL in euangelia'],
                                  url_suppl: ['https://purl.stanford.edu/kd310gm7424', 'https://purl.stanford.edu/dx969tv9730']
    end

    it 'has other fields that are present in parker data' do
      expect(document).to include repository_ssim: ['UK, Cambridge, Corpus Christi College, Parker Library'],
                                  identifier_displayLabel_ssim: ['Source ID-|-CCCC:69', 'Stanley ID-|-L. 14', 'T. James ID-|-135']
    end
  end

  context 'collection' do
    let(:druid) { 'dx969tv9730' }

    context 'to_solr' do
      subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

      before do
        stub_request(:get, 'https://purl-fetcher-url.example.com/collections/druid:dx969tv9730/purls?page=1&per_page=1000').to_return(
          body: '{ "purls": [], "pages": {} }', status: 200
        )
      end

      it 'has correct doc id' do
        expect(document[:id]).to eq druid
      end

      it 'has the correct collection tag' do
        expect(document[:collection_type]).to eq 'Digital Collection'
      end

      it 'has correct resource type' do
        expect(document[:format_main_ssim]).to include 'Collection'
      end

      it 'has correct content metadata type' do
        expect(document[:content_metadata_type_ssm]).to include 'file'
      end

      it 'parses and reformats the timestamp to iso8601' do
        expect(document[:last_updated]).to eq '2015-07-14T02:40:23Z'
      end
    end
  end

  context 'virtual object' do
    let(:druid) { 'ws947mh3822' }

    context 'to_solr' do
      subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

      it 'has content metadata fields' do
        expect(document).to include content_metadata_type_ssim: ['image'],
                                    content_metadata_first_image_file_name_ssm: ['PC0170_s1_E_0204'],
                                    content_metadata_first_image_width_ssm: ['4488'],
                                    content_metadata_first_image_height_ssm: ['6738'],
                                    content_metadata_image_iiif_info_ssm: %w(https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204/info.json https://stacks.stanford.edu/image/iiif/tp006ms8736%2FPC0170_s1_E_0205/info.json),
                                    thumbnail_square_url_ssm: %w(https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204/square/100,100/0/default.jpg https://stacks.stanford.edu/image/iiif/tp006ms8736%2FPC0170_s1_E_0205/square/100,100/0/default.jpg),
                                    thumbnail_url_ssm: %w(https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204/full/!400,400/0/default.jpg https://stacks.stanford.edu/image/iiif/tp006ms8736%2FPC0170_s1_E_0205/full/!400,400/0/default.jpg),
                                    large_image_url_ssm: %w(https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204/full/!1000,1000/0/default.jpg https://stacks.stanford.edu/image/iiif/tp006ms8736%2FPC0170_s1_E_0205/full/!1000,1000/0/default.jpg),
                                    full_image_url_ssm: %w(https://stacks.stanford.edu/image/iiif/ts786ny5936%2FPC0170_s1_E_0204/full/!3000,3000/0/default.jpg https://stacks.stanford.edu/image/iiif/tp006ms8736%2FPC0170_s1_E_0205/full/!3000,3000/0/default.jpg)
      end
    end
  end

  context 'rarebooks object' do
    let(:druid) { 'hm136qv0310' }

    context 'to_solr' do
      subject(:document) { indexed_documents(dor_harvester).first&.with_indifferent_access }

      it 'has publisher fields' do
        expect(document).to include publisher_ssim: ['D. Margand et C. Fatout'],
                                    publisher_ssi: ['D. Margand et C. Fatout'],
                                    publisher_tesim: ['D. Margand et C. Fatout']
      end
    end
  end
end
