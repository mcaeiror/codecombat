CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/guide-view'
Article = require 'models/Article'
utils = require 'lib/utils'

# let's implement this once we have the docs database schema set up

module.exports = class LevelGuideView extends CocoView
  template: template
  id: 'guide-view'
  className: 'tab-pane'

  constructor: (options) ->
    @firstOnly = options.firstOnly
    @docs = options?.docs ? options.level.get('documentation') ? {}
    general = @docs.generalArticles or []
    specific = @docs.specificArticles or []

    articles = options.supermodel.getModels(Article)
    articleMap = {}
    articleMap[article.get('original')] = article for article in articles
    general = (articleMap[ref.original] for ref in general)
    general = (article.attributes for article in general when article)

    @docs = specific.concat(general)
    @docs = $.extend(true, [], @docs)
    @docs = [@docs[0]] if @firstOnly and @docs[0]
    doc.html = marked(utils.i18n doc, 'body') for doc in @docs
    doc.name = (utils.i18n doc, 'name') for doc in @docs
    doc.slug = _.string.slugify(doc.name) for doc in @docs
    super()

  getRenderData: ->
    c = super()
    c.docs = @docs
    c

  afterRender: ->
    super()
    if @docs.length is 1
      @$el.html(@docs[0].html)
    else
      # incredible hackiness. Getting bootstrap tabs to work shouldn't be this complex
      @$el.find('.nav-tabs li:first').addClass('active')
      @$el.find('.tab-content .tab-pane:first').addClass('active')
      @$el.find('.nav-tabs a').click(@clickTab)
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'guide-open', volume: 1

  clickTab: (e) =>
    @$el.find('li.active').removeClass('active')
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'guide-tab-switch', volume: 1

  afterInsert: ->
    super()
    Backbone.Mediator.publish 'level:docs-shown', {}

  onHidden: ->
    Backbone.Mediator.publish 'level:docs-hidden', {}
