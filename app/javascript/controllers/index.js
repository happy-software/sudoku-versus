// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import BoardController from "./board_controller"
import ClipboardController from "./clipboard_controller"
import RematchModalController from "./rematch_modal_controller"

application.register("board", BoardController)
application.register("clipboard", ClipboardController)
application.register("rematch-modal", RematchModalController)
