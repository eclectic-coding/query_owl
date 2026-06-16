import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import TableFilterController from "query_owl/table_filter_controller"

const application = Application.start()
application.register("table-filter", TableFilterController)