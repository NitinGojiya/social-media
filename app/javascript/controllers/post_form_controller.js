import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["generateButton", "form", "login", "imageUrl", "imageFile", "caption", "ig", "fb", "btnPost", "li", "twitter", "schedule", "dateinput"]

  connect() {

    document.getElementById('image-file-input').addEventListener('change', function (event) {
      const files = Array.from(event.target.files);
      const images = files.filter(file => file.type.startsWith('image/'));
      const videos = files.filter(file => file.type.startsWith('video/'));

      if (images.length > 20 || videos.length > 1) {
        alert('You can select only 1 video and up to 20 images.');
        event.target.value = ''; // Clear selection
      }
    });
    this.updateButtonLabel()
    const is_schedule = this.scheduleTarget.checked;
    if (is_schedule) {
      this.updateButtonLabel()
    }
  }

  previewPost(event) {
    const checkbox = event.target;
    const platform = checkbox.name.replace("post_to_", ""); // fb | ig | li | twitter
    const previewEl = document.getElementById(`${platform}Preview`);

    if (!previewEl) return;

    // Show/hide this platform's preview
    if (checkbox.checked) {
      previewEl.classList.remove("hidden");

      switch (platform) {
        case "fb":
          this.updateFacebookPreview();
          break;
        case "ig":
          this.updateInstagramPreview();
          break;
        case "li":
          this.updateLinkedinPreview();
          break;
        case "twitter":
          this.updateTwitterPreview();
          break;
      }
    } else {
      previewEl.classList.add("hidden");
    }

    // Update label text depending on whether any are selected
    const anyChecked =
      (this.hasFbTarget && this.fbTarget.checked) ||
      (this.hasIgTarget && this.igTarget.checked) ||
      (this.hasLiTarget && this.liTarget.checked) ||
      (this.hasTwitterTarget && this.twitterTarget.checked);

    document.getElementById("previewLabel").textContent =
      anyChecked ? "Disable preview" : "Enable preview";
  }

  disablePreview() {
    document.getElementById("previewLabel").textContent = "Enable preview";
    document.getElementById("facebookPreview")?.classList.add("hidden");
    document.getElementById("instagramPreview")?.classList.add("hidden");
    document.getElementById("linkedinPreview")?.classList.add("hidden");
    document.getElementById("twitterPreview")?.classList.add("hidden");

    // Uncheck all platform checkboxes
    if (this.hasFbTarget) this.fbTarget.checked = false;
    if (this.hasIgTarget) this.igTarget.checked = false;
    if (this.hasLiTarget) this.liTarget.checked = false;
    if (this.hasTwitterTarget) this.twitterTarget.checked = false;
  }


  // --- ✅ Facebook ---
  updateFacebookPreview() {
    const caption = this.captionTarget.value.trim();
    const imageUrl = this.imageUrlTarget.value.trim();
    const files = this.hasImageFileTarget ? Array.from(this.imageFileTarget.files) : [];

    const fbController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="facebook-preview"]'),
      "facebook-preview"
    );

    this.loadMediaAndUpdate(files, imageUrl, caption, fbController);
  }

  // --- ✅ Instagram ---
  updateInstagramPreview() {
    const caption = this.captionTarget.value.trim();
    const imageUrl = this.imageUrlTarget.value.trim();
    const files = this.hasImageFileTarget ? Array.from(this.imageFileTarget.files) : [];

    const igController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="instagram-preview"]'),
      "instagram-preview"
    );

    this.loadMediaAndUpdate(files, imageUrl, caption, igController);
  }

  // --- ✅ LinkedIn ---
  updateLinkedinPreview() {
    const caption = this.captionTarget.value.trim();
    const imageUrl = this.imageUrlTarget.value.trim();
    const files = this.hasImageFileTarget ? Array.from(this.imageFileTarget.files) : [];

    const liController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="linkedin-preview"]'),
      "linkedin-preview"
    );

    this.loadMediaAndUpdate(files, imageUrl, caption, liController);
  }

  // --- ✅ Twitter ---
  updateTwitterPreview() {
    const caption = this.captionTarget.value.trim();
    const imageUrl = this.imageUrlTarget.value.trim();
    const files = this.hasImageFileTarget ? Array.from(this.imageFileTarget.files) : [];

    const twController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="twitter-preview"]'),
      "twitter-preview"
    );

    this.loadMediaAndUpdate(files, imageUrl, caption, twController);
  }

  // --- Shared loader for all networks ---
  loadMediaAndUpdate(files, imageUrl, caption, controller) {
    if (!controller) return;

    if (files.length > 0) {
      const mediaArray = [];
      let loadedCount = 0;

      files.forEach((file) => {
        const reader = new FileReader();
        reader.onload = (e) => {
          const type = file.type.startsWith("video") ? "video" : "image";
          mediaArray.push({ type, url: e.target.result });

          loadedCount++;
          if (loadedCount === files.length) {
            controller.update(caption, mediaArray);
          }
        };
        reader.readAsDataURL(file);
      });

    } else if (imageUrl) {
      const lowerUrl = imageUrl.toLowerCase();
      const isVideo = /\.(mp4|webm|ogg)$/i.test(lowerUrl);

      controller.update(caption, [
        { type: isVideo ? "video" : "image", url: imageUrl }
      ]);

    } else {
      controller.update(caption, []);
    }
  }

  updateButtonLabel() {
    const is_schedule = this.scheduleTarget.checked;

    // Show or hide the date input
    if (is_schedule) {
        flatpickr(this.dateinputTarget, {
      enableTime: true,
      inline: true,         // always open calendar
      dateFormat: "Y-m-d H:i",
      defaultDate: document.getElementById("datetime").value
    })
      this.dateinputTarget.classList.remove("hidden");
      console.log(document.getElementById("datetime").value)
    } else {
        flatpickr(this.dateinputTarget, {
      enableTime: true,
      inline: false,         // always open calendar
      dateFormat: "Y-m-d H:i",
      defaultDate: document.getElementById("datetime").value
    })
      this.dateinputTarget.classList.add("hidden");
    }

    // Update button text
    this.btnPostTarget.textContent = is_schedule ? "Schedule Post" : "Post Now";
  }

  dateChanged(event) {
    this.updateButtonLabel()
  }

  async submit(event) {
    event.preventDefault()
    const postToIG = this.hasIgTarget ? this.igTarget.checked : false
    const postToFB = this.hasFbTarget ? this.fbTarget.checked : false
    const postToLI = this.hasLiTarget ? this.liTarget.checked : false
    const postToTwitter = this.hasTwitterTarget ? this.twitterTarget.checked : false

    document.getElementById('my_modal_1').close()
    if (postToIG || postToFB) {
      await this.FbIgSubmit()
    }
    if (postToLI) {
      await this.submitLinkedIn()
    }
    if (postToTwitter) {
      await this.submitTwitter()
    }
    window.location.reload()
  }

  async FbIgSubmit() {
    const imageUrl = this.imageUrlTarget.value.trim()
    const caption = this.captionTarget.value.trim()

    const postToIG = this.hasIgTarget ? this.igTarget.checked : false
    const postToFB = this.hasFbTarget ? this.fbTarget.checked : false
    const scheduleToPOST = this.hasScheduleTarget ? this.scheduleTarget.checked : false

    const fileInput = this.hasImageFileTarget ? this.imageFileTarget.files : []
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
      Array.from(fileInput).forEach(file => {
        formData.append("image_file[]", file)
      })
    } else {
      formData.append("image_url", imageUrl)
    }

    formData.append("caption", caption)
    formData.append("post_to_ig", postToIG ? "1" : "0")
    formData.append("post_to_fb", postToFB ? "1" : "0")
    formData.append("schedule_to_post", scheduleToPOST ? "1" : "0")

    const rawDate = this.formTarget.querySelector("input[name='date']")?.value
    // const datePart = rawDate || new Date().toISOString().slice(0, 10)
    // const formattedDate = `${datePart} 00:00:00.000000000 +0000`
    formData.append("date", rawDate)

    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const loader = document.getElementById("fullscreen-loader")
    loader.style.display = "flex"

    try {
      const response = await fetch("/ig_fb_posts", {
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
        //  alert("Failed: " + (data.error || data.errors?.join(", ") || "Unknown error"))

      }
    } catch (err) {
      loader.style.display = "none"
      console.error("Unexpected Error:", err)
      alert("An unexpected error occurred.")
    }
  }

  async submitLinkedIn() {
    const caption = this.captionTarget.value.trim()
    const files = this.hasImageFileTarget ? this.imageFileTarget.files : []
    const scheduleToPOST = this.hasScheduleTarget ? this.scheduleTarget.checked : false

    if (!files.length) {
      alert("Please upload at least one image file for LinkedIn.")
      return
    }

    if (!caption) {
      alert("Please enter a caption for the LinkedIn post.")
      return
    }

    const formData = new FormData()

    // Append all selected files
    for (let i = 0; i < files.length; i++) {
      formData.append("image_file[]", files[i]) // Notice the `[]`
    }

    formData.append("caption", caption)
    formData.append("schedule_to_post", scheduleToPOST ? "1" : "0")

    const rawDate = this.formTarget.querySelector("input[name='date']")?.value
    formData.append("date", rawDate)

    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const loader = document.getElementById("fullscreen-loader")
    loader.style.display = "flex"

    try {
      const response = await fetch("/linkedin/create_linkedin_post", {
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
        this.updateButtonLabel()
      } else {
        // alert("Failed: " + (data.error || data.errors?.join(", ") || "Unknown error"))
      }

    } catch (err) {
      loader.style.display = "none"
      console.error("Unexpected Error:", err)
      alert("An unexpected error occurred: " + err.message)
    }
  }

  async submitTwitter() {
    const caption = this.captionTarget.value.trim()
    const files = this.hasImageFileTarget ? this.imageFileTarget.files : []
    const scheduleToPOST = this.hasScheduleTarget ? this.scheduleTarget.checked : false

    if (!caption) {
      alert("Please enter a caption for the Twitter post.")
      return
    }

    // Optional: Validate Twitter's image limit (e.g. 4)
    if (files.length > 4) {
      alert("Twitter allows up to 4 images.")
      return
    }

    const formData = new FormData()

    for (let i = 0; i < files.length; i++) {
      formData.append("image_file[]", files[i])
    }

    formData.append("caption", caption)
    formData.append("schedule_to_post", scheduleToPOST ? "1" : "0")

    const rawDate = this.formTarget.querySelector("input[name='date']")?.value
    formData.append("date", rawDate)

    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const loader = document.getElementById("fullscreen-loader")
    loader.style.display = "flex"

    try {
      const response = await fetch("/twitter/create_twitter_post", {
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
        this.updateButtonLabel()
        // Optionally reload or redirect
        window.location.reload()
        // alert("Twitter post created successfully!")
      } else {
        alert("Failed: " + (data.error || "Unknown error"))
      }
    } catch (err) {
      loader.style.display = "none"
      console.error("Unexpected Error:", err)
      alert("An unexpected error occurred: " + err.message)
    }
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
