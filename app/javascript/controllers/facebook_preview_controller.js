import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["caption", "mediaWrapper", "prevButton", "nextButton"];

  connect() {
    this.currentIndex = 0;
    this.mediaArray = [];
  }

  /**
   * Update the Facebook preview.
   * @param {string} caption - Caption text
   * @param {Array} mediaArray - [{ type: "image"|"video", url: "..." }]
   */
  update(caption = "", mediaArray = []) {
    this.captionTarget.textContent = caption || "Your caption will appear here";
    this.mediaArray = mediaArray;
    this.currentIndex = 0;

    this.renderMedia();
    this.updateNavigation();
  }

  renderMedia() {
    this.mediaWrapperTarget.innerHTML = ""; // Clear old content
    const count = this.mediaArray.length;

    if (count === 0) return;

    if (count === 1) {
      // Single image/video → full height, centered
      this.mediaWrapperTarget.className =
        "flex items-center justify-center h-[500px] bg-black";
      const el = this.createMediaElement(this.mediaArray[0], "w-full h-full");
      this.mediaWrapperTarget.appendChild(el);
    } else if (count === 2) {
      // Two side by side
      this.renderGrid(this.mediaArray, "grid-cols-2");
    } else if (count === 3) {
      // One big left, two stacked right
      this.mediaWrapperTarget.className = "grid grid-cols-2 gap-1 h-[500px]";
      const big = this.createMediaElement(this.mediaArray[0], "col-span-1 row-span-2");
      const topRight = this.createMediaElement(this.mediaArray[1]);
      const bottomRight = this.createMediaElement(this.mediaArray[2]);
      this.mediaWrapperTarget.append(big, topRight, bottomRight);
    } else if (count === 4) {
      // 2x2 grid
      this.renderGrid(this.mediaArray.slice(0, 4), "grid-cols-2");
    } else {
      // 5 or more → show first 4 and overlay on the last
      this.mediaWrapperTarget.className = "grid grid-cols-2 gap-1 h-[500px]";
      this.mediaArray.slice(0, 4).forEach((m, i) => {
        const el = this.createMediaElement(m);
        if (i === 3) {
          // Overlay with +N
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
  wrapper.className = `relative w-full h-full overflow-hidden ${extraClasses}`;

  let element;
  if (type === "video") {
    element = document.createElement("video");
    element.controls = true;
    element.playsInline = true;
    element.className = "w-full h-full object-cover bg-black";
    element.src = url;

    // ▶️ Play overlay
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

    wrapper.appendChild(element);
    wrapper.appendChild(playOverlay);
  } else {
    element = document.createElement("img");
    element.src = url;
    element.className = "w-full h-full object-cover";
    wrapper.appendChild(element);
  }

  return wrapper;
}

  renderGrid(mediaArray, gridClass) {
    this.mediaWrapperTarget.className = `grid ${gridClass} gap-1 h-[500px]`;
    mediaArray.forEach((m) => {
      this.mediaWrapperTarget.appendChild(this.createMediaElement(m));
    });
  }

  updateNavigation() {
    // Grid preview doesn't need prev/next buttons
    this.prevButtonTarget.classList.add("hidden");
    this.nextButtonTarget.classList.add("hidden");
  }

  // Reserved for carousel mode
  prevMedia() {}
  nextMedia() {}
  slideToCurrent() {}
}
