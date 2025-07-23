import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "imageUrl", "caption", "ig", "fb"]

  async submit(event) {
    document.getElementById('my_modal_1').close();
    event.preventDefault() // Prevent default form submission

    const imageUrl = this.imageUrlTarget.value.trim()
    const caption = this.captionTarget.value.trim()
    const postToIG = this.igTarget.checked
    const postToFB = this.fbTarget.checked

    if (!postToIG && !postToFB) {
      alert("Please select at least one platform.")
      return
    }

    if (imageUrl === "") {
      alert("Image URL cannot be empty.")
      return
    }

    // Default endpoint
    const endpoint = "/instagrams"

    const formData = new FormData()
    formData.append("image_url", imageUrl)
    formData.append("caption", caption)
    if (postToIG) formData.append("post_to_ig", "1")
    if (postToFB) formData.append("post_to_fb", "1")

    const csrfToken = document.querySelector("meta[name='csrf-token']").content

    const loader = document.getElementById("fullscreen-loader");
    loader.style.display = "flex"; // Show loader
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

      if (response.ok) {
        // alert(data.message || "Post submitted successfully!")
        loader.style.display = "none";

        this.formTarget.reset()

      } else {
        alert("Failed: " + (data.error || "Unknown error"))
      }
    } catch (err) {
      console.error("Unexpected Error:", err)
      alert("An unexpected error occurred.")
    }
  }
}
