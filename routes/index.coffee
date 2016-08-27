express = require "express"
router = do express.Router

class Routes

  constructor: (survey) ->
    # GET home page
    router.get "/", (req, res, next) ->
      details =
        title : survey.getTitle()
      res.render "index", details
    router.get "/survey/:q?", (req, res, next) ->
      q = {}
      if req.params.q? and req.params.q > 0
        q = survey.getQuestion --req.params.q, req.session.answers
        if !q?
          if survey.isPreview() and !survey.isLocked()
            newAnswers = if req.body.contrib? then req.body.contrib else req.session.contrib
            survey.mergeAnswers newAnswers unless !newAnswers?
            req.session.contrib = null
          req.session.answers = {}
          q =
            question : survey.getPostface()
            last : true
      else
        q =
          question : survey.getPreamble()
        if req.session.contrib?
          q.contrib = req.session.contrib
      res.set { "Content-Type" : "application/json" }
      res.json q

    router.post "/survey/add", (req, res, next) ->
      if survey.isPreview() && !survey.isLocked() && req.body?
        req.session.contrib = req.body
        res.json { status : true }
      else
        res.json { status : false }

    router.post "/survey/add_question", (req, res, next) ->
      if survey.isPreview() && !survey.isLocked() && req.body?
        survey.mergeQuestion req.body
        res.json { status : true }
      else
        res.json { status : false }

    router.post "/survey/answer", (req, res, next) ->
      if !req.session.id?
        req.session.id = do uniqueId
      if survey.isActive() && !survey.isLocked() && req.body?
        req.session.answers = req.body
        survey.mergeResults req.session.id, req.body
        res.json { status : true }
      else
        res.json { status : false }

  getRouter: () ->
    router

  uniqueId = (length=32) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

module.exports = Routes
