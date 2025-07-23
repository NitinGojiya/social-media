import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "postName", "postFile", "instagramCheckbox"]

  async submit(event) {
    event.preventDefault()

    const formData = new FormData(this.formTarget)

    // Upload to Instagram if selected
    if (this.instagramCheckboxTarget.checked) {
      await this.uploadToInstagram(formData)
    }

    // Submit form via fetch (or Rails UJS if you're using that)
    const response = await fetch(this.formTarget.action || "/instagrams", {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "application/json" // Optional: for Rails JSON API
      }
    })

    if (response.ok) {
      // ✅ Only close modal after everything is done
      this.element.closest("dialog").close()
    } else {
      console.error("Form submission failed")
    }
  }

  async uploadToInstagram(formData) {
    const file = this.postFileTarget.files[0]
    if (!file) return

    const base64 = await this.convertToBase64(file)

    const response = await fetch("/instagrams/upload_base64_image", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify({
        image: base64,
        postName: this.postNameTarget.value
      })
    })

    if (!response.ok) {
      console.error("Instagram upload failed")
    }
  }

  convertToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onloadend = () => resolve(reader.result)
      reader.onerror = reject
      reader.readAsDataURL(file)
    })
  }
}
