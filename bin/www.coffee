#!/usr/bin/env coffee

survey = null

###
 Module dependencies.
###
debug = (require "debug") "simple-survey:server"
http = require "http"
get_opt = require "node-getopt"
cfg = new (require "../lib/configuration")
survey_model = require "../models/survey"

###
 Read command line options and parameters
###
opt = get_opt.create [
        ['c', 'config=ARG', 'Configuration file. (default is config.yaml)'],
        ['s', 'survey=ARG', 'Survey YAML file. (default is based on config file or survey.yaml)'],
        ['o', 'output=ARG', 'Output YAML file to save modifed survey to. (default is based on config file or survey-updated.yaml)']
        ['r', 'results=ARG', 'Results YAML file to save answers to. (default is based on config file or survey-results.yaml)']
      ]
      .bindHelp()
      .parseSystem()


###
 Load configuration file
###
cfg_file = '../config.yaml'
if opt.options.config?
  cfg_file = opt.options.config

cfg.readConfig cfg_file
.then (config) ->

  if opt.options.survey?
    survey_file = opt.options.survey
  else
    survey_file = do config.getSurveyFile
  survey_file = '../survey.yaml' unless survey_file?

  if opt.options.output?
    save_file = opt.options.output
  else
    save_file = do config.getSaveFile
  save_file = '../survey-updated.yaml' unless save_file?

  if opt.options.results?
    results_file = opt.options.results
  else
    results_file = do config.getResultsFile
  results_file = '../survey-results.yaml' unless results_file?

  survey = new survey_model survey_file, save_file, results_file, config.isLocked()
  mode = do config.getMode
  survey.loadSurvey(mode)
  .then () ->
    survey.loadResults()
    .then () ->
      app_setup = new (require "../app") survey, config

      ###
       Create HTTP server.
      ###
      server = http.createServer app_setup.getApp()

      ###
       Normalize a port into a number, string, or false.
      ###
      normalizePort = (val) ->
        port = parseInt(val, 10)
        if isNaN(port)
          # named pipe
          return val
        if port >= 0
          # port number
          return port
        false

      ###
       Event listener for HTTP server "error" event.
      ###

      onError = (error) ->
        if error.syscall isnt "listen"
          throw error

        bind = if typeof port is "string" then "Pipe " + port else "Port " + port

        # handle specific listen errors with friendly messages
        switch error.code
          when "EACCES"
            console.error bind + " requires elevated privileges"
            process.exit 1
          when "EADDRINUSE"
            console.error bind + " is already in use"
            process.exit 1
          else throw error

      ###
       Event listener for HTTP server "listening" event.
      ###

      onListening = () ->
        addr = do server.address
        bind = if typeof addr is "string" then "pipe " + addr else "port " + addr.port
        debug "Listening on " + bind

      ###
       Get port from environment and store in Express.
      ###
      port = normalizePort(process.env.PORT or "3000")
      app_setup.getApp().set "port", port

      ###
       Listen on provided port, on all network interfaces.
      ###
      server.listen port, 'localhost'
      server.on "error", onError
      server.on "listening", onListening
    .fail (f) ->
      console.log "Results file not set. (#{f})"
      process.exit 2
  .fail (f) ->
    console.log "Survey file #{survey_file} not found. (#{f})"
    process.exit 2
.fail (f) ->
  console.log "Config file #{cfg_file} not found. (#{f})"
  process.exit 2

module.exports = survey
