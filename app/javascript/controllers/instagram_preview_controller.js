import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["caption", "mediaWrapper", "dots"];

  connect() {
    this.currentIndex = 0;
    this.mediaArray = [];
    this.update();
  }

  update(caption = "", mediaArray = []) {
    this.captionTarget.textContent = caption || "Write a caption...";
    this.mediaArray = mediaArray;
    this.currentIndex = 0;
    this.renderMedia();
  }

  renderMedia() {
    this.mediaWrapperTarget.innerHTML = "";
    this.dotsTarget.innerHTML = "";

    // hide arrows & dots if less than 2 items
    this.toggleNavigation(this.mediaArray.length > 1);

    if (this.mediaArray.length === 0) {
      const img = document.createElement("img");
      img.src = "https://placehold.co/600x600/000000/34d399?text=your+post";
      img.className = "w-full h-full object-cover";
      this.mediaWrapperTarget.appendChild(img);
      return;
    }

    this.mediaArray.forEach((item, i) => {
      const slide = document.createElement("div");
      slide.className = "flex-shrink-0 w-full h-full";
      slide.appendChild(this.createMediaElement(item));
      this.mediaWrapperTarget.appendChild(slide);

      // dots only if >1
      if (this.mediaArray.length > 1) {
        const dot = document.createElement("div");
        dot.className =
          "w-2 h-2 rounded-full " +
          (i === 0 ? "bg-white" : "bg-gray-500 opacity-60");
        this.dotsTarget.appendChild(dot);
      }
    });

    this.updateCarousel();
  }

  createMediaElement({ type, url }) {
    const wrapper = document.createElement("div");
    wrapper.className = "relative w-full h-full overflow-hidden";

    if (type === "video") {
      const video = document.createElement("video");
      video.src = url;
      video.controls = true;
      video.playsInline = true;
      video.className = "w-full h-full object-cover bg-black";

      const playOverlay = document.createElement("div");
      playOverlay.className =
        "absolute inset-0 flex items-center justify-center pointer-events-none";
      playOverlay.innerHTML = `
        <div class="w-14 h-14 rounded-full bg-black bg-opacity-60 flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg"
               class="w-7 h-7 text-white" fill="currentColor"
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
      img.className = "w-full h-full object-cover";
      wrapper.appendChild(img);
    }
    return wrapper;
  }

  prev() {
    if (this.mediaArray.length < 2) return;
    this.currentIndex =
      (this.currentIndex - 1 + this.mediaArray.length) %
      this.mediaArray.length;
    this.updateCarousel();
  }

  next() {
    if (this.mediaArray.length < 2) return;
    this.currentIndex =
      (this.currentIndex + 1) % this.mediaArray.length;
    this.updateCarousel();
  }

  updateCarousel() {
    const offset = -this.currentIndex * 100;
    this.mediaWrapperTarget.style.transform = `translateX(${offset}%)`;

    if (this.mediaArray.length > 1) {
      Array.from(this.dotsTarget.children).forEach((dot, i) => {
        dot.className =
          "w-2 h-2 rounded-full " +
          (i === this.currentIndex
            ? "bg-white"
            : "bg-gray-500 opacity-60");
      });
    }
  }

  toggleNavigation(show) {
    // find arrow buttons in DOM
    const prevBtn = this.element.querySelector(
      "[data-action='click->instagram-preview#prev']"
    );
    const nextBtn = this.element.querySelector(
      "[data-action='click->instagram-preview#next']"
    );

    if (prevBtn && nextBtn) {
      prevBtn.style.display = show ? "flex" : "none";
      nextBtn.style.display = show ? "flex" : "none";
    }
    this.dotsTarget.style.display = show ? "flex" : "none";
  }
}
