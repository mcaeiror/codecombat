CocoView = require 'views/kinds/CocoView'
template = require 'templates/achievements/achievement-popup'
User = require '../../models/User'
Achievement = require '../../models/Achievement'

module.exports = class AchievementPopup extends CocoView
  className: 'achievement-popup'
  template: template

  constructor: (options) ->
    @achievement = options.achievement
    @earnedAchievement = options.earnedAchievement
    @container = options.container or @getContainer()
    @popup = options.container
    @popup ?= true
    @className += ' popup' if @popup
    super options
    @render()

  calculateData: ->
    currentLevel = me.level()
    nextLevel = currentLevel + 1
    currentLevelExp = User.expForLevel(currentLevel)
    nextLevelXP = User.expForLevel(nextLevel)
    totalExpNeeded = nextLevelXP - currentLevelExp
    expFunction = @achievement.getExpFunction()
    currentXP = me.get 'points', true
    if @achievement.isRepeatable()
      achievedXP = expFunction(@earnedAchievement.get('previouslyAchievedAmount')) * @achievement.get('worth') if @achievement.isRepeatable()
    else
      achievedXP = @achievement.get 'worth', true
    previousXP = currentXP - achievedXP
    leveledUp = currentXP - achievedXP < currentLevelExp
    #console.debug 'Leveled up' if leveledUp
    alreadyAchievedPercentage = 100 * (previousXP - currentLevelExp) / totalExpNeeded
    alreadyAchievedPercentage = 0 if alreadyAchievedPercentage < 0 # In case of level up
    newlyAchievedPercentage = if leveledUp then 100 * (currentXP - currentLevelExp) / totalExpNeeded else  100 * achievedXP / totalExpNeeded

    #console.debug "Current level is #{currentLevel} (#{currentLevelExp} xp), next level is #{nextLevel} (#{nextLevelXP} xp)."
    #console.debug "Need a total of #{nextLevelXP - currentLevelExp}, already had #{previousXP} and just now earned #{achievedXP} totalling on #{currentXP}"

    data =
      title: @achievement.i18nName()
      imgURL: @achievement.getImageURL()
      description: @achievement.i18nDescription()
      level: currentLevel
      currentXP: currentXP
      newXP: achievedXP
      leftXP: nextLevelXP - currentXP
      oldXPWidth: alreadyAchievedPercentage
      newXPWidth: newlyAchievedPercentage
      leftXPWidth: 100 - newlyAchievedPercentage - alreadyAchievedPercentage

  getRenderData: ->
    c = super()
    _.extend c, @calculateData()
    c.style = @achievement.getStyle()
    c.popup = true
    c.$ = $ # Allows the jade template to do i18n
    c

  render: ->
    super()
    @container.prepend @$el
    if @popup
      hide = =>
        return if @destroyed
        @$el.animate {left: 600}, =>
          @$el.remove()
          @destroy()
      @$el.animate left: 0
      @$el.on 'click', hide
      _.delay hide, 10000 unless $('#editor-achievement-edit-view').length

  getContainer: ->
    unless @container
      @container = $('.achievement-popup-container')
      unless @container.length
        $('body').append('<div class="achievement-popup-container"></div>')
        @container = $('.achievement-popup-container')
    @container

  afterRender: ->
    super()
    _.delay @initializeTooltips, 1000 # TODO this could be smoother

  initializeTooltips: ->
    $('.progress-bar').tooltip()
