import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const btn = event.currentTarget

    // Fill the modal form fields
    document.getElementById("post-id").value = btn.dataset.postId
    document.getElementById("post-caption").value = btn.dataset.postCaption
    document.getElementById("post-scheduled-at").value = this.formatDateTime(btn.dataset.postScheduledAt)

    document.getElementById("post-fb").checked = btn.dataset.postFb === "1"
    document.getElementById("post-ig").checked = btn.dataset.postIg === "1"
    document.getElementById("post-linkedin").checked = btn.dataset.postLinkedin === "1"

    // Set the form action dynamically
    // document.getElementById("edit-form").action = `/scheduled_update/${btn.dataset.postId}`
    const form = document.getElementById("edit-form");
    form.action = form.action.replace("/scheduled_update/0", `/scheduled_update/${btn.dataset.postId}`);

    // Show the modal
    document.getElementById("edit-modal").classList.remove("hidden")
  }

  close() {
    document.getElementById("edit-modal").classList.add("hidden")
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

}
