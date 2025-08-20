import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["caption", "mediaWrapper"];

  connect() {
    this.mediaArray = [];
  }

  /**
   * Update the Twitter-like preview
   * @param {string} caption
   * @param {Array} mediaArray [{ type: "image"|"video", url: "..." }]
   */
  update(caption = "", mediaArray = []) {
    this.captionTarget.textContent = caption || "";
    this.mediaArray = mediaArray;

    this.renderMedia();
  }

  renderMedia() {
    this.mediaWrapperTarget.innerHTML = "";
    const count = this.mediaArray.length;

    if (count === 0) {
      const placeholder = document.createElement("img");
      placeholder.src =
        "https://placehold.co/800x450/e2e8f0/334155?text=Your+Twitter+Post";
      placeholder.className = "w-full h-auto object-cover";
      this.mediaWrapperTarget.className =
        "w-full bg-gray-200 aspect-video flex items-center justify-center";
      this.mediaWrapperTarget.appendChild(placeholder);
      return;
    }

    if (count === 1) {
      this.mediaWrapperTarget.className =
        "flex items-center justify-center bg-black max-h-[500px]";
      const el = this.createMediaElement(this.mediaArray[0], "w-full h-full");
      this.mediaWrapperTarget.appendChild(el);
    } else if (count === 2) {
      this.renderGrid(this.mediaArray, "grid-cols-2");
    } else if (count === 3) {
      this.mediaWrapperTarget.className = "grid grid-cols-2 gap-1 max-h-[500px]";
      const big = this.createMediaElement(this.mediaArray[0], "col-span-1 row-span-2");
      const topRight = this.createMediaElement(this.mediaArray[1]);
      const bottomRight = this.createMediaElement(this.mediaArray[2]);
      this.mediaWrapperTarget.append(big, topRight, bottomRight);
    } else if (count === 4) {
      this.renderGrid(this.mediaArray, "grid-cols-2");
    } else {
      this.mediaWrapperTarget.className = "grid grid-cols-2 gap-1 max-h-[500px]";
      this.mediaArray.slice(0, 4).forEach((m, i) => {
        const el = this.createMediaElement(m);
        if (i === 3) {
          const overlay = document.createElement("div");
          overlay.className =
            "absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center text-white text-2xl font-bold";
          overlay.textContent = `+${count - 4}`;
          el.classList.add("relative");
          el.appendChild(overlay);
        }
        this.mediaWrapperTarget.appendChild(el);
      });
    }
  }

  createMediaElement({ type, url }, extraClasses = "") {
    const wrapper = document.createElement("div");
    wrapper.className = `relative w-full h-full rounded-lg overflow-hidden ${extraClasses}`;

    if (type === "video") {
      const video = document.createElement("video");
      video.src = url;
      video.controls = true;
      video.playsInline = true;
      video.className = "w-full h-full rounded-lg object-cover bg-black";

      // Play overlay like Twitter
      const playOverlay = document.createElement("div");
      playOverlay.className =
        "absolute inset-0 flex items-center justify-center pointer-events-none";
      playOverlay.innerHTML = `
        <div class="w-12 h-12 rounded-full bg-black bg-opacity-60 flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg"
               class="w-6 h-6 text-white" fill="currentColor"
               viewBox="0 0 20 20">
            <path d="M6 4l10 6-10 6V4z" />
          </svg>
        </div>
      `;

      wrapper.appendChild(video);
      wrapper.appendChild(playOverlay);
    } else {
      const img = document.createElement("img");
      img.src = url;
      img.className = "w-full rounded-lg h-full object-cover";
      wrapper.appendChild(img);
    }

    return wrapper;
  }

  renderGrid(mediaArray, gridClass) {
    this.mediaWrapperTarget.className = `grid ${gridClass} gap-1 max-h-[500px]`;
    mediaArray.forEach((m) => {
      this.mediaWrapperTarget.appendChild(this.createMediaElement(m));
    });
  }
}
