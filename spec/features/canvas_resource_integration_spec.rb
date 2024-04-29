# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Canvas resource integration test', type: :feature do
  subject(:document) { SolrDocument.new(to_solr_hash) }

  let(:raw_canvas) { JSON.parse(File.read(file)) }
  let(:enhanced_canvas) do
    raw_canvas.merge(manifest_label: 'Awesome sauce!', range_labels: %w(Label1 Label2))
  end
  let(:resource) { CanvasResource.new(exhibit:, data: enhanced_canvas) }
  let(:file) { 'spec/fixtures/iiif/fh878gz0315-canvas-521.json' }
  let(:exhibit) { create(:exhibit) }
  let(:to_solr_hash) { indexed_documents(resource).first }
  let(:annolist_file) { 'spec/fixtures/iiif/fh878g0315-text-f254r.json' }
  let(:annolist_url) { 'https://dms-data.stanford.edu/data/manifests/Parker/fh878gz0315/list/text-f254r.json' }
  let(:title_display_search_fields) do
    %w(title_display title_uniform_search)
  end

  before :all do
    ActiveJob::Base.queue_adapter = :inline # block until indexing has committed
  end

  before do
    allow(Faraday).to receive(:get).with(annolist_url).and_return(
      instance_double(Faraday::Response, body: File.read(annolist_file))
    )
  end

  after :all do
    ActiveJob::Base.queue_adapter = :test # restore
  end

  it 'can write the document to solr' do
    expect { resource.reindex }.not_to raise_error
  end

  context 'to_solr' do
    subject(:canvas) { document.canvas }

    it 'has correct format' do
      expect(document['format_main_ssim']).to include 'Page details'
    end

    it 'has correct title fields' do
      title_display_search_fields.each do |field_name|
        expect(document[field_name]).to eq ['f. 254 r: Awesome sauce!']
      end
      expect(document['title_sort']).to eq ['Awesome sauce!: f. 254 r']
    end

    it 'has canvas attributes' do
      expect(canvas.id).to eq 'canvas-0fa395980b05e493948e0e2b50debd42'
      expect(canvas.iiif_id).to eq 'https://dms-data.stanford.edu/data/manifests/Parker/fh878gz0315/canvas/canvas-521'
      expect(canvas.label).to eq 'f. 254 r: Awesome sauce!'
    end

    it 'has parent references' do
      expect(document['iiif_manifest_url_ssi']).to eq ['https://purl.stanford.edu/fh878gz0315/iiif/manifest']
    end

    it 'has canvas annotations' do
      expect(canvas.annotation_lists).to include annolist_url
      expect(canvas.annotations.size).to eq 26
      expect(canvas.annotations).to include 'scæððig wæs his fæder geoffrod for ure alysed'
    end

    it 'has range labels' do
      expect(document['range_labels_tesim']).to eq %w(Label1 Label2)
    end

    it 'has document reference' do
      expect(document['related_document_id_ssim']).to include 'fh878gz0315'
    end
  end
end
