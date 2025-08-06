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

      // ✅ ADD "+" ICON TO EACH DAY CELL
    dayCellDidMount: function (info) {
  const plusBtn = document.createElement("button")
  plusBtn.textContent = "+"
  plusBtn.classList.add("fc-add-button")
  plusBtn.setAttribute("type", "button") // prevent form submit


  plusBtn.title = "Add new post"

  // Ensure day cell is positioned
  info.el.style.position = "relative"
  info.el.appendChild(plusBtn)

  // Hover (desktop)
  info.el.addEventListener("mouseenter", () => {
    plusBtn.style.display = "inline-block"
  })
  info.el.addEventListener("mouseleave", () => {
    plusBtn.style.display = "none"
  })

  // Touch (mobile)
  info.el.addEventListener("touchstart", () => {
    plusBtn.style.display = "inline-block"
    setTimeout(() => {
      plusBtn.style.display = "none"
    }, 3000) // auto-hide after 3s
  })

  // ✅ Button click action
plusBtn.addEventListener("click", () => {
  // Show modal
  if (typeof my_modal_1 !== 'undefined' && typeof my_modal_1.showModal === 'function') {
    my_modal_1.showModal()
  }

  // Set the clicked date in the datetime-local input
  const datetimeInput = document.getElementById("datetime")
  if (datetimeInput) {
    const date = new Date(info.date)

    // Optional: set default time to 09:00
    date.setHours(9)
    date.setMinutes(0)

    // Format to "YYYY-MM-DDTHH:MM"
    const formatted = date.toISOString().slice(0,16)
    datetimeInput.value = formatted
    datetimeInput.classList.remove("hidden")
    document.getElementById("postButton").innerHTML = "Schedule Post"
  }

  // Check the checkbox
  const checkbox = document.getElementById("schedule-checkbox")
  if (checkbox) {
    checkbox.checked = true
  }
})

}

      ,

      eventDidMount: function (info) {
        const isHoliday = info.event.extendedProps.holiday
        const isPosted = info.event.extendedProps.posted

        const eventEl = info.el

        // Dot
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

          const titleEl = eventEl.querySelector('.fc-event-title')
          if (titleEl) {
            titleEl.prepend(dot)
          }
        }

        // Hover button
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

        const contentEl = eventEl.querySelector(".fc-event-title") || eventEl
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
      }
    })

    calendar.render()

    function showModal(event) {
      const title = event.title
      const date = event.start.toLocaleString()
      const isHoliday = event.extendedProps.holiday
      const isPosted = event.extendedProps.posted
      const image = event.extendedProps.image

      document.getElementById("event-modal-title").textContent = title
      document.getElementById("event-modal-date").textContent = `Date: ${date}`
      document.getElementById("event-modal-type").textContent =
        isHoliday ? "Type: Holiday" : isPosted ? "Status: Posted" : "Status: Scheduled Post"

      const imageEl = document.getElementById("event-modal-image")
      if (image) {
        imageEl.src = image
        imageEl.style.display = "block"
      } else {
        imageEl.style.display = "none"
      }

      document.getElementById("event_details_modal").showModal()
    }


  }
}
