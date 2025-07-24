import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "imageUrl", "caption", "ig", "fb"]

  async submit(event) {
    document.getElementById('my_modal_1').close();
    event.preventDefault();

    const imageUrl = this.imageUrlTarget.value.trim()
    const caption = this.captionTarget.value.trim()

    const postToIG = this.hasIgTarget ? this.igTarget.checked : false
    const postToFB = this.hasFbTarget ? this.fbTarget.checked : false

    if (!postToIG && !postToFB) {
      alert("Please select at least one platform.")
      return
    }

    if (imageUrl === "") {
      alert("Image URL cannot be empty.")
      return
    }

    const endpoint = "/instagrams"

    const formData = new FormData()
    formData.append("image_url", imageUrl)
    formData.append("caption", caption)
    formData.append("post_to_ig", postToIG ? "1" : "0")
    formData.append("post_to_fb", postToFB ? "1" : "0")

    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const loader = document.getElementById("fullscreen-loader")
    loader.style.display = "flex"

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: formData
      })

      const data = await response.json()

      loader.style.display = "none"
      if (response.ok) {
        this.formTarget.reset()
      } else {
        alert("Failed: " + (data.error || "Unknown error"))
      }
    } catch (err) {
      loader.style.display = "none"
      console.error("Unexpected Error:", err)
      alert("An unexpected error occurred.")
    }
  }
}
