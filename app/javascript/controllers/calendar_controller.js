import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["schedule", "dateinput"]

  connect() {
    const calendar = new window.FullCalendar.Calendar(this.element, {
      headerToolbar: {
        start: 'dayGridMonth,timeGridWeek,timeGridDay',
        center: 'title',
        end: 'prevYear,prev,next,nextYear'
      },

      events: "/calendar_events",

      // Month view: "+" on each day cell
      dayCellDidMount: function (info) {
        const plusBtn = document.createElement("button")
        plusBtn.textContent = "+"
        plusBtn.classList.add("fc-add-button")
        plusBtn.setAttribute("type", "button")
        plusBtn.title = "Add new post"

        info.el.style.position = "relative"
        info.el.appendChild(plusBtn)

        info.el.addEventListener("mouseenter", () => {
          plusBtn.style.display = "inline-block"
        })
        info.el.addEventListener("mouseleave", () => {
          plusBtn.style.display = "none"
        })
        info.el.addEventListener("touchstart", () => {
          plusBtn.style.display = "inline-block"
          setTimeout(() => {
            plusBtn.style.display = "none"
          }, 3000)
        })

        plusBtn.addEventListener("click", () => {
          if (typeof my_modal_1 !== 'undefined' && typeof my_modal_1.showModal === 'function') {
            my_modal_1.showModal()
          }

          const datetimeInput = document.getElementById("datetime")
          if (datetimeInput) {
            const date = new Date(info.date)
            date.setHours(9)
            date.setMinutes(0)
            datetimeInput.value = formatDateForDatetimeLocal(date)
            datetimeInput.classList.remove("hidden")
            document.getElementById("postButton").innerHTML = "Schedule Post"
          }

          const checkbox = document.getElementById("schedule-checkbox")
          if (checkbox) {
            checkbox.checked = true
          }
        })
      },

      // Week/Day view: "+" on time slot hover
      slotLaneDidMount: function (info) {
        if (!["timeGridWeek", "timeGridDay"].includes(calendar.view.type)) return

        const plusBtn = document.createElement("button")
        plusBtn.textContent = "+"
        plusBtn.classList.add("fc-add-button")
        plusBtn.setAttribute("type", "button")
        plusBtn.title = "Add new post"


        plusBtn.style.width = "100%"
        plusBtn.style.height = "20px"


        info.el.style.position = "relative"
        info.el.appendChild(plusBtn)

        info.el.addEventListener("mouseenter", () => {
          plusBtn.style.display = "inline-block"
        })
        info.el.addEventListener("mouseleave", () => {
          plusBtn.style.display = "none"
        })
        info.el.addEventListener("touchstart", () => {
          plusBtn.style.display = "inline-block"
          setTimeout(() => {
            plusBtn.style.display = "none"
          }, 3000)
        })

        plusBtn.addEventListener("click", () => {
          if (typeof my_modal_1 !== 'undefined' && typeof my_modal_1.showModal === 'function') {
            my_modal_1.showModal()
          }

          const datetimeInput = document.getElementById("datetime")
          if (datetimeInput) {
            const date = new Date(info.date)
            datetimeInput.value = formatDateForDatetimeLocal(date)
            datetimeInput.classList.remove("hidden")
            document.getElementById("postButton").innerHTML = "Schedule Post"
          }

          const checkbox = document.getElementById("schedule-checkbox")
          if (checkbox) {
            checkbox.checked = true
          }
        })
      },

      dateClick: function (info) {
        if (["timeGridWeek", "timeGridDay"].includes(calendar.view.type)) {
          if (typeof my_modal_1 !== 'undefined' && typeof my_modal_1.showModal === 'function') {
            my_modal_1.showModal()
          }

          const datetimeInput = document.getElementById("datetime")
          if (datetimeInput) {
            const date = new Date(info.date)
            datetimeInput.value = formatDateForDatetimeLocal(date)
            datetimeInput.classList.remove("hidden")
            document.getElementById("postButton").innerHTML = "Schedule Post"
          }

          const checkbox = document.getElementById("schedule-checkbox")
          if (checkbox) {
            checkbox.checked = true
          }
        }
      },

      eventDidMount: function (info) {
        const isHoliday = info.event.extendedProps.holiday
        const isPosted = info.event.extendedProps.posted
        const image = info.event.extendedProps.image
        const isVideo = info.event.extendedProps.video // new flag

        const eventEl = info.el
        eventEl.style.cursor = "pointer"

        const titleEl = eventEl.querySelector('.fc-event-title')
        if (titleEl) {
          if (image || isVideo) {
            const img = document.createElement("img")

            if (isVideo) {
              img.src = "https://images.unsplash.com/photo-1637592156141-d41fb6234e71?q=80&w=1253&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D" // your static video icon path
              img.alt = "Video"
            } else {
              img.src = image
              img.alt = "Event Image"
            }

            img.style.width = "50px"
            img.style.height = "50px"
            img.style.objectFit = "cover"
            img.style.marginRight = "5px"
            img.style.verticalAlign = "middle"
            img.style.borderRadius = "4px"
            titleEl.prepend(img)
          }

          if (typeof isHoliday !== "undefined" || typeof isPosted !== "undefined") {
            const dot = document.createElement("div")
            dot.style.width = "10px"
            dot.style.height = "10px"
            dot.style.borderRadius = "50%"
            dot.style.display = "inline-block"
            dot.style.cursor = "pointer"
            dot.style.marginRight = "5px"
            dot.style.verticalAlign = "middle"
            dot.style.backgroundColor = isHoliday
              ? "red"
              : isPosted
                ? "green"
                : "gray"
            titleEl.prepend(dot)
          }
        }

        const button = document.createElement("button")
        button.textContent = "Details"
        button.style.display = "none"
        button.style.marginLeft = "10px"
        button.style.padding = "2px 6px"
        button.style.fontSize = "12px"
        button.style.cursor = "pointer"
        button.classList.add("event-detail-button")

        button.addEventListener("click", function (e) {
          e.stopPropagation()
          e.preventDefault()
          if (!info.event.extendedProps.holiday) {
            showModal(info.event)
          }
        })

        const contentEl = titleEl || eventEl
        contentEl.appendChild(button)

        eventEl.addEventListener("mouseenter", () => {
          button.style.display = "inline-block"
        })
        eventEl.addEventListener("mouseleave", () => {
          button.style.display = "none"
        })
        eventEl.addEventListener("touchstart", () => {
          button.style.display = "inline-block"
          setTimeout(() => {
            button.style.display = "none"
          }, 3000)
        })
      },


      eventClick: function (info) {
        info.jsEvent.preventDefault()
        if (!info.event.extendedProps.holiday) {
          showModal(info.event)
        }
      },
    })

    calendar.render()

    function formatDateForDatetimeLocal(date) {
      const pad = (n) => String(n).padStart(2, '0')
      return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
    }
    function showModal(event) {
      const title = event.title
      const date = event.start.toLocaleString()
      const isHoliday = event.extendedProps.holiday
      const isPosted = event.extendedProps.posted
      const image = event.extendedProps.image
      const isVideo = event.extendedProps.video // from backend

      document.getElementById("event-modal-title").textContent = title
      document.getElementById("event-modal-date").textContent = `Date: ${date}`
      document.getElementById("event-modal-type").textContent =
        isHoliday ? "Type: Holiday" : isPosted ? "Status: Posted" : "Status: Scheduled Post"

      const imageEl = document.getElementById("event-modal-image")
      const videoEl = document.getElementById("event-modal-video")
      const videoSrc = document.getElementById("event-modal-video-src")

      if (isVideo) {
        // Hide image, show video
        imageEl.style.display = "none"
        videoEl.style.display = "block"
        videoSrc.src = image // here 'image' contains the direct video URL
        videoEl.load()
      } else if (image) {
        // Show image, hide video
        imageEl.src = image
        imageEl.alt = "Event Image"
        imageEl.style.display = "block"
        videoEl.style.display = "none"
      } else {
        // No media
        imageEl.style.display = "none"
        videoEl.style.display = "none"
      }

      document.getElementById("event_details_modal").showModal()
    }

  }
}
