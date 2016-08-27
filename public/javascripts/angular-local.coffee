baseUrl = 'http://localhost:3000/'

angular.module 'nospaceFilter', []
  .filter 'cleanLabel', () ->
    (input) ->
      input.replace /[^a-zA-Z]+/g, '_'

survey = angular.module 'survey', ['nospaceFilter']

survey.controller 'QuestionnaireController', ['$scope', '$http', ($scope, $http) ->

  $scope.qCount = 0
  $scope.aCount = 0
  $scope.nQCount = 0
  $scope.selectedAnswers = []
  $scope.newAnswers = {}
  $scope.newQuestions = []

  nextQuestion = (qc) ->
    if qc > 0
      ajaxUrl = baseUrl + 'survey/' + qc
    else
      ajaxUrl = baseUrl + 'survey/'
    $http.get ajaxUrl
    .then (response) ->
      d = response.data
      $scope.title = d.title
      $scope.question = d.question
      $scope.answers = d.answers
      $scope.type = d.type
      $scope.last = d.last
      $scope.preview = d.preview
      $scope.locked = d.locked
      $scope.oneChoice = d.oneChoice
      if d.contrib and Object.keys($scope.newAnswers).length is 0
        $scope.newAnswers = d.contrib
    , (error) ->
      console.log error

  saveInput = () ->
    $scope.selectedAnswers[$scope.qCount] = {} unless $scope.selectedAnswers[$scope.qCount]?
    if $scope.oneChoice?
      $scope.selectedAnswers[$scope.qCount][$scope.question] = $scope.oneChoice
    else if $scope.answers?
      for a in $scope.answers
        $scope.selectedAnswers[$scope.qCount][a.id] = a.model
    delete $scope.oneChoice
    if $scope.preview and !$scope.locked
      $http.post baseUrl + 'survey/add', $scope.newAnswers
      .then () ->
        return true
      , (error) ->
        console.log error
    else if !$scope.locked
      $http.post baseUrl + 'survey/answer', $scope.selectedAnswers
      .then () ->
        return true
      , (error) ->
        console.log error

  nextQuestion 0

  $scope.nextClick = () ->
    do saveInput
    nextQuestion ++$scope.qCount unless $scope.last
    $scope.newAnswers[$scope.qCount] = [] unless $scope.newAnswers[$scope.qCount]? and $scope.newAnswers[$scope.qCount].length > 0

  $scope.prevClick = () ->
    do saveInput
    nextQuestion --$scope.qCount unless $scope.qCount is 0
    console.log $scope.qCount, $scope.newAnswers

  $scope.addAnswer = () ->
    $scope.newAnswers[$scope.qCount].push { id : "answer-#{$scope.aCount++}" } unless $scope.locked or $scope.type is 'binary'

  $scope.removeAnswer = (i) ->
    $scope.newAnswers[$scope.qCount].splice i, 1

  $scope.addNewQuestion = () ->
    $scope.nQCount++

  $scope.saveQuestion = () ->
    q =
      title : $scope.newTitle
      question : $scope.newQuestion
      type : $scope.newQType
      answers : $scope.newAnswers[$scope.qCount]
    delete $scope.newTitle
    delete $scope.newQuestion
    $scope.newAnswers[$scope.qCount] = []
    $scope.newQuestions.push q
    $http.post baseUrl + 'survey/add_question', q, () ->
      return true
    , (error) ->
      console.log error

  $scope.canAddAnswer = () ->
    existingQ = $scope.answers? and $scope.type isnt 'binary'
    newQ = $scope.newTitle and $scope.newQuestion \
            and $scope.newQType? \
            and ($scope.newQType isnt 'binary' or $scope.newAnswers[$scope.qCount].length < 2)
    (existingQ || newQ) && $scope.preview && !$scope.locked
]
