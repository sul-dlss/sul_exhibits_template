SirTrevor.Blocks.SolrDocumentsEmbed = (function(){
  const spotlightSetIiifFields = SirTrevor.Blocks.SolrDocumentsEmbed.prototype.setIiifFields
  const spotlightItemPanelIiifFields = SirTrevor.Blocks.SolrDocumentsEmbed.prototype._itemPanelIiifFields

  return SirTrevor.Blocks.SolrDocumentsEmbed.extend({
    item_options: function() {
      const formId = this.formId("maxheight");
      return [
        `<label for="${formId}">Maximum height of viewer (in pixels)</label>`,
        `<input id="${formId}" type="number" class="form-control" placeholder="600" name="maxheight" />`
      ].join(' ');
    },
    setIiifFields: function(panel, manifest_data, initialize) {
      const panelElement = panel[0]
      const itemId = panelElement.dataset.id
      const iiifCanvasId = panelElement.querySelector(`input[name="item[${itemId}][iiif_canvas_id]"]`)
      const oldCanvasId = iiifCanvasId.value

      spotlightSetIiifFields.call(this, panel, manifest_data, initialize)
      if (oldCanvasId !== iiifCanvasId.value) {
        iiifCanvasId.dispatchEvent(new Event('change', { bubbles: false }))
      }
    },
    _itemPanelIiifFields: function(index, autocomplete_data) {
      const spotliightIiifFields = spotlightItemPanelIiifFields.call(this, index, autocomplete_data)

      // This is the initialization of all block level thumbnails.
      const thumbnails = this?.el.querySelectorAll('input[name*="[thumbnail_image_url]"]')
      thumbnails?.forEach(thumbnail => {
        thumbnail.dispatchEvent(new Event('change', { bubbles: false }))
      })

      return [
        spotliightIiifFields,
        "<input type='hidden' name='item[" + index + "][iiif_initial_viewer_config]' value='" + (autocomplete_data.iiif_initial_viewer_config) + "'/>",
      ].join("\n");
    },
  });
})();

// work around for https://bugs.chromium.org/p/chromium/issues/detail?id=1262589&q=contenteditable&can=1
if (navigator.userAgentData && navigator.userAgentData.brands &&
    Boolean(navigator.userAgentData.brands.find(function(b) { return b.brand === 'Chromium' && parseFloat(b.version, 10) >= 95 && parseFloat(b.version, 10) < 97; }))) {
  SirTrevor.Blocks.Text.prototype.editorHTML = "<div class=\"st-text-block\" spellcheck=\"false\" contenteditable=\"true\"></div>";
}

// Override the alt text link url so it goes to Stanford's guidelines
SirTrevor.Locales.en.blocks.alt_text_guidelines = $.extend(SirTrevor.Locales.en.blocks.alt_text_guidelines, {
  link_url: 'https://uit.stanford.edu/accessibility/concepts/images' 
});
