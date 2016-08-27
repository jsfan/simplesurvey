YAML = require "yamljs"
Q = require "q"
lock = new (require "rwlock")
fs = require "fs"

class Survey

  constructor: (@survey_file, @save_file, @results_file, @locked) ->
    self = @
    self.survey = {}
    self.results = {}

  loadSurvey: (mode='active') ->
    self = @
    self.mode = mode
    surveyLoaded = do Q.defer
    if self.survey_file?
      lock.readLock "survey_io", (release) ->
        YAML.load self.survey_file, (survey) ->
          if survey?
            self.survey = survey
            surveyLoaded.resolve survey
          else
            surveyLoaded.reject true
          do release
    else
      surveyLoaded.reject false
    surveyLoaded.promise

  loadResults: () ->
    self = @
    resultsLoaded = do Q.defer
    if self.results_file?
      lock.readLock "results_io", (release) ->
        YAML.load self.results_file, (results) ->
          if !results?
            results = {}
          self.results = results
          resultsLoaded.resolve results
          do release
    else if self.isLocked() or self.isPreview()
      resultsLoaded.resolve false
    else
      resultsLoaded.reject false
    resultsLoaded.promise

  mergeAnswers: (answers) ->
    self = @
    for q, i in self.survey.questions
      if answers[i+1]?
        console.log answers[i+1], a
        for a in answers[i+1]
          q.answers.push a.name
    self.survey

  mergeQuestion: (question) ->
    self = @
    answers = []
    for a in question.answers
      answers.push a.name
    question.answers = answers
    self.survey.questions.push question

  saveSurvey: () ->
    self = @
    surveySaved = do Q.defer
    survey_yaml = YAML.stringify self.survey, 10
    lock.writeLock "survey_io", (release) ->
      fs.writeFile self.save_file, survey_yaml, "utf8", (err) ->
        if err?
          surveySaved.reject err
        else
          surveySaved.resolve true
        do release
    surveySaved.promise

  mergeResults: (id, results) ->
    self = @
    self.results[id] = results
    console.log self.results[id]

  saveResults: () ->
    self = @
    resultsSaved = do Q.defer
    results_yaml = YAML.stringify self.results, 10
    lock.writeLock "results_io", (release) ->
      fs.writeFile self.results_file, results_yaml, "utf8", (err) ->
        if err?
          resultsSaved.reject err
        else
          resultsSaved.resolve true
        do release
    resultsSaved.promise

  getTitle: () ->
    self = @
    self.survey.title

  getPreamble: () ->
    self = @
    self.survey.preamble[self.mode]

  getPostface: () ->
    self = @
    self.survey.postface[self.mode]

  getQuestion: (i, selectedAnswers=null) ->
    self = @
    q = self._clone self.survey.questions[i]
    proc_answers = []
    if q?
      for a in q.answers
        answer =
          str : a
        if q.type isnt 'binary' and q.type isnt 'radio'
          answer.id = a.replace /[^a-zA-Z0-9]/g, '_'
          try
            answer.model = selectedAnswers[i+1][answer.id]
          catch
        else
          answer.id = q.question.replace /[^a-zA-Z0-9]/g, '_'
        proc_answers.push answer
      if q.type is 'binary' or q.type is 'radio'
        try
          q.oneChoice = selectedAnswers[i+1][q.question]
        catch
      q.answers = proc_answers
      q.preview = self.isPreview() unless !q?
    q

  isLocked: () ->
    self = @
    self.locked

  isPreview: () ->
    self = @
    self.mode is 'preview'

  isActive: () ->
    self = @
    self.mode is 'active'

  _clone: (obj) ->
    self = @
    if not obj? or typeof obj isnt 'object'
      return obj

    if obj instanceof Date
      return new Date(obj.getTime())

    if obj instanceof RegExp
      flags = ''
      flags += 'g' if obj.global?
      flags += 'i' if obj.ignoreCase?
      flags += 'm' if obj.multiline?
      flags += 'y' if obj.sticky?
      return new RegExp(obj.source, flags)

    newInstance = new obj.constructor()

    for key of obj
      newInstance[key] = self._clone obj[key]

    return newInstance

module.exports = Survey
