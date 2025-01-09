// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import bootstrap from 'bootstrap/dist/js/bootstrap'

import Blacklight from "blacklight-frontend";
import githubAutoCompleteElement from "@github/auto-complete-element";


//= require 'honeybadger'
import './bibliography'
import './cited_documents'
import './blacklight_gallery'
import './blacklight_heatmaps'
import './blacklight_oembed'
import './full_text_collapse'
import './index_status_typeahead'
import './exhibit_search_typeahead'
import './nested_related_items'
import 'openseadragon'
import 'spotlight-frontend/app/assets/javascripts/spotlight/spotlight.esm'
import './sir_trevor_block_overrides'
import './table_of_contents'
import './site_search_type_toggle'
import './blacklight_heatmaps_overrides'
