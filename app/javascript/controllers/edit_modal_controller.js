import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["generateButton","caption"]
  open(event) {
    const btn = event.currentTarget

    // Fill the modal form fields
    document.getElementById("post-id").value = btn.dataset.postId
    document.getElementById("post-caption").value = btn.dataset.postCaption
    document.getElementById("post-scheduled-at").value = this.formatDateTime(btn.dataset.postScheduledAt)

    document.getElementById("post-fb").checked = btn.dataset.postFb === "1"
    document.getElementById("post-ig").checked = btn.dataset.postIg === "1"
    document.getElementById("post-linkedin").checked = btn.dataset.postLinkedin === "1"
    document.getElementById("post-twitter").checked = btn.dataset.postTwitter === "1";

    // Set the form action dynamically
    // document.getElementById("edit-form").action = `/scheduled_update/${btn.dataset.postId}`
    const form = document.getElementById("edit-form");
    form.action = form.action.replace("/scheduled_update/0", `/scheduled_update/${btn.dataset.postId}`);

    // Show the modal
    document.getElementById("edit").classList.remove("hidden")
  }

  close() {
    document.getElementById('edit').close();

  }

 formatDateTime(datetimeString) {
  if (!datetimeString) return ""

  const date = new Date(datetimeString)

  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')

  return `${year}-${month}-${day}T${hours}:${minutes}` // Local time format
}

  async generate() {
    const prompt = this.captionTarget.value || "Generate a caption for my post"

    // Show loader
    this.captionTarget.disabled = true
    const originalText = this.captionTarget.value
    this.captionTarget.value = "Generating caption..."
    this.generateButtonTarget.innerHTML = `<i class="fas fa-spinner fa-spin"></i>`
    try {
      const response = await fetch("/ai/generate_caption", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ prompt: prompt })
      })

      if (response.ok) {
        const data = await response.json()
        this.captionTarget.value = data.caption
      } else {
        alert("Something went wrong generating the caption.")
        this.captionTarget.value = originalText
      }
    } catch (error) {
      console.error("Request failed:", error)
      this.captionTarget.value = originalText
      this.generateButtonTarget.innerHTML = `<i class="fa-solid fa-wand-magic-sparkles"></i>`
      // alert("Something went wrong.")
    } finally {
      this.captionTarget.disabled = false
      this.generateButtonTarget.innerHTML = `<i class="fa-solid fa-wand-magic-sparkles"></i>`
    }
  }

}
