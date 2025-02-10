class ImageViewerStateModal {
  constructor() {
    this.listenForModal()
    this.listenForViewerUpdates()
  }

  get modal() { return document.getElementById("blacklight-modal") }
  get saveViewerStateElement() { return document.getElementById('request-state') }
  get viewerIframeElement() { return document.querySelector('.oembed-widget iframe, iframe.mirador-embed-wrapper') }

  listenForModal() {
    document.addEventListener('loaded.blacklight.blacklight-modal', (e) => {
      if (this.saveViewerStateElement) {
        this.listenForSaveRequest()

        // TODO: After the jsbundling-rails PR is merged, import blacklight-oembed, avoid jquery/scope selector to the modal.
        $('[data-embed-url]').oEmbed()
      }
    })
  }

  get origin() {
    const iframe = this.viewerIframeElement
    if (!iframe) return null
    return new URL(iframe.src).origin
  }

  listenForSaveRequest() {
    this.saveViewerStateElement.addEventListener('click', (event) => {
      event.preventDefault()
      event.target.disabled = true
      this.formId = event.target.dataset.formId
      this.itemId = event.target.dataset.itemId
      // Request the current state from the viewer
      this.viewerIframeElement.contentWindow.postMessage(JSON.stringify({ type: 'requestState' }), this.origin)
    })
  }

  listenForViewerUpdates() {
    window.addEventListener('message', (event) => {
      // Ignore messages from other origins
      if (event.origin !== this.origin) return

      const viewerEventData = this.parseViewerData(event?.data)
      if (viewerEventData) {
        this.modal.close()
        this.dispatchViewerStateUpdate(viewerEventData, this.formId, this.itemId)
        this.formId = null
        this.itemId = null
      }
    })
  }

  dispatchViewerStateUpdate(viewerEventData, formId, itemId) {
    const formElement = document.getElementById(formId)
    const viewerEvent = new CustomEvent('imageViewerStateUpdate', {
      detail: { ...viewerEventData, itemId },
      bubbles: false
    })
    formElement.dispatchEvent(viewerEvent)
  }

  parseViewerData(data) {
    let parsedData;
    try {
      parsedData = typeof data === 'string' ? JSON.parse(data) : data
    } catch {
      console.error('Failed to parse the data from the image viewer')
      return null
    }
    if (parsedData.type !== "stateResponse" || parsedData.source !== "sul-embed-m3") return null
    return parsedData.data
  }
}

// TODO: This can be moved and the class exported after the jsbundling-rails PR is merged.
document.addEventListener('DOMContentLoaded', () => {
  new ImageViewerStateModal()
})