import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const calendar = new window.FullCalendar.Calendar(this.element, {
      headerToolbar: {
      start: 'dayGridMonth,timeGridWeek,timeGridDay',
      center: 'title',
      end: 'prevYear,prev,next,nextYear'
    },

      events: "/calendar_events"
    })

    calendar.render()
  }
}
