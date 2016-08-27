YAML = require "yamljs"
Q = require "q"

class Configuration

  constructor: () ->
    self = @
    self.config = {}

  readConfig: (cfg_file) ->
    self = @
    configRead = do Q.defer
    if !cfg_file?
      do configRead.reject
    YAML.load cfg_file, (res) ->
      self.config = res
      if res?
        configRead.resolve self
      else
        do configRead.reject
    configRead.promise

  getSurveyFile: () ->
    self = @
    self.config.surveyFile

  getSaveFile: () ->
    self = @
    self.config.saveFile

  getResultsFile: () ->
    self = @
    self.config.resultsFile

  getMode: () ->
    self = @
    self.config.mode

  isPreview: () ->
    self = @
    self.config.mode is 'preview'

  isLocked: () ->
    self = @
    self.config.locked

  getSessionName: () ->
    self = @
    self.config.sessionName

  getSessionKeys: () ->
    self = @
    self.config.sessionKeys

module.exports = Configuration