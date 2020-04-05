express = require "express"
path = require "path"
#favicon = require "serve-favicon"
logger = require "morgan"
cookieParser = require "cookie-parser"
bodyParser = require "body-parser"
session = require "cookie-session"


class AppSetup

  constructor: (@survey, @config) ->
    self = @
    self.routes = new (require "./routes/index") self.survey

    self.app = do express

    # view engine setup
    self.app.set "views", path.join(__dirname, "views")
    self.app.set "view engine", "pug"

    # uncomment after placing your favicon in /public
    #self.app.use favicon(path.join(__dirname, "public", "favicon.ico"))
    self.app.use logger("dev")
    self.app.use bodyParser.json()
    self.app.use bodyParser.urlencoded({ extended: false })
    self.app.use cookieParser()
    self.app.use require("stylus").middleware(path.join(__dirname, "public"))
    self.app.use express.static(path.join(__dirname, "public"))
    self.app.use session({ name: self.config.getSessionName(), keys: self.config.getSessionKeys() })

    self.app.use "/", self.routes.getRouter()

    # catch 404 and forward to error handler
    self.app.use (req, res, next) ->
      err = new Error("Not Found")
      err.status = 404
      next(err)

    # error handlers

    # development error handler
    # will print stacktrace
    if self.app.get("env") is "development"
      self.app.use (err, req, res, next) ->
        res.status (err.status or 500)
        res.render "error", {
          message: err.message,
          error: err
        }

    # production error handler
    # no stacktraces leaked to user
    self.app.use (err, req, res, next) ->
      res.status (err.status or 500)
      res.render "error", {
        message: err.message,
        error: {}
      }

    # save every 2 min
    if self.survey.isPreview() && !self.survey.isLocked()
      setInterval () ->
        console.log 'Saving survey.'
        do self.survey.saveSurvey
      , 30000

    if self.survey.isActive() && !self.survey.isLocked()
      setInterval () ->
        console.log 'Saving survey results.'
        do self.survey.saveResults
      , 30000

  getApp: () ->
    self = @
    self.app

module.exports = AppSetup
