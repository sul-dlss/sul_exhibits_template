import 'blacklight-oembed'
import Blacklight from "blacklight-frontend";

Blacklight.onLoad(function() {
  $('[data-embed-url]').oEmbed();
});
