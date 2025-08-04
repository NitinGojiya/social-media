import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const calendar = new window.FullCalendar.Calendar(this.element, {
      headerToolbar: {
        start: 'dayGridMonth,timeGridWeek,timeGridDay',
        center: 'title',
        end: 'prevYear,prev,next,nextYear'
      },

      events: "/calendar_events",

      eventDidMount: function (info) {
        const isHoliday = info.event.extendedProps.holiday
        const isPosted = info.event.extendedProps.posted

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

          const titleEl = info.el.querySelector('.fc-event-title')
          if (titleEl) {
            titleEl.prepend(dot)
          }
        }
      },

      eventClick: function (info) {
  info.jsEvent.preventDefault()
  if (!info.event.extendedProps.holiday) {
    const event = info.event
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
      imageEl.style.display = "none" // Hide image if none
    }

    document.getElementById("event_details_modal").showModal()
  }
}

    })

    calendar.render()
  }
}
