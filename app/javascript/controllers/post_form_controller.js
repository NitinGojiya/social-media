import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "imageUrl", "imageFile", "caption", "ig", "fb", "btnPost", "li"]

  connect() {
    this.updateButtonLabel()
  }

  updateButtonLabel() {
    const rawDate = this.formTarget.querySelector("input[name='date']")?.value
    const selectedDate = new Date(rawDate)
    const today = new Date()

    const isToday =
      selectedDate.getFullYear() === today.getFullYear() &&
      selectedDate.getMonth() === today.getMonth() &&
      selectedDate.getDate() === today.getDate()

    this.btnPostTarget.textContent = isToday ? "Post Now" : "Schedule Post"
  }

  dateChanged(event) {
    this.updateButtonLabel()
  }

  async submit(event) {
    event.preventDefault()
    const postToIG = this.hasIgTarget ? this.igTarget.checked : false
    const postToFB = this.hasFbTarget ? this.fbTarget.checked : false
    const postToLI = this.hasLiTarget ? this.liTarget.checked : false

    document.getElementById('my_modal_1').close()
    if (postToIG || postToFB) {
      await this.FbIgSubmit()
    }
    if (postToLI) {
      await this.submitLinkedIn()
    }
  window.location.reload()
  }

  async FbIgSubmit() {
    const imageUrl = this.imageUrlTarget.value.trim()
    const caption = this.captionTarget.value.trim()

    const postToIG = this.hasIgTarget ? this.igTarget.checked : false
    const postToFB = this.hasFbTarget ? this.fbTarget.checked : false
    const fileInput = this.hasImageFileTarget ? this.imageFileTarget.files[0] : null

    if (!postToIG && !postToFB) {
      alert("Please select at least one platform.")
      return
    }

    if (!imageUrl && !fileInput) {
      alert("Please provide either an image URL or upload a file.")
      return
    }

    const formData = new FormData()
    if (fileInput) {
      formData.append("image_file", fileInput)
    } else {
      formData.append("image_url", imageUrl)
    }

    formData.append("caption", caption)
    formData.append("post_to_ig", postToIG ? "1" : "0")
    formData.append("post_to_fb", postToFB ? "1" : "0")

    const rawDate = this.formTarget.querySelector("input[name='date']")?.value
    const datePart = rawDate || new Date().toISOString().slice(0, 10)
    const formattedDate = `${datePart} 00:00:00.000000000 +0000`
    formData.append("date", formattedDate)

    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const loader = document.getElementById("fullscreen-loader")
    loader.style.display = "flex"

    try {
      const response = await fetch("/instagrams", {
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
        // this.formTarget.reset()
        this.updateButtonLabel()
      } else {
        alert("Failed: " + (data.error || "Unknown error"))
      }
    } catch (err) {
      loader.style.display = "none"
      console.error("Unexpected Error:", err)
      alert("An unexpected error occurred.")
    }
  }

  async submitLinkedIn() {
    const caption = this.captionTarget.value.trim()
    const fileInput = this.hasImageFileTarget ? this.imageFileTarget.files[0] : null

    if (!fileInput) {
      alert("Please upload an image file for LinkedIn.")
      return
    }

    if (!caption) {
      alert("Please enter a caption for the LinkedIn post.")
      return
    }

    const formData = new FormData()
    // formData.append("image_file", fileInput)
    const fileClone = fileInput.slice(0, fileInput.size, fileInput.type)
    formData.append("image_file", fileClone)

    formData.append("caption", caption)


    const rawDate = this.formTarget.querySelector("input[name='date']")?.value
    const datePart = rawDate || new Date().toISOString().slice(0, 10)
    const formattedDate = `${datePart} 00:00:00.000000000 +0000`
    formData.append("date", formattedDate)

    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const loader = document.getElementById("fullscreen-loader")
    loader.style.display = "flex"

    try {
      const response = await fetch("/linkedin/post_with_image", {
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
        // this.formTarget.reset()
        this.updateButtonLabel()
        // window.location.reload()
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
