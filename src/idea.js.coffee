Utils =
  generate_id: ->
    str = 'abcdefghijklmnopqrstuvwxyz0123456789'
    l = str.length
    re = ''

    for i in [0...7]
      r = ~~(Math.random() * l)
      re = re + str[r]

    return re


class Idea
  constructor: (@text)->
    # STATES = ['common', 'editing_text', 'active']
    @init_fsm()
    @id = Utils.generate_id()
  
  init_fsm: ->
    @fsm = StateMachine.create
      initial: 'common'
      events: [
        { name: 'select',         from: 'common',       to: 'active'}
        { name: 'edit_text',      from: 'active',       to: 'editing_text' }
        { name: 'stop_edit_text', from: 'editing_text', to: 'active' }
      ]

    # 切换到节点文字编辑状态
    @fsm.onenterediting_text = =>
      @$el.addClass 'editing-text'
      # 计算 textarea 的初始大小
      t_width = @$text.width()
      t_height = @$text.height()

      @$text_ipter = jQuery '<textarea>'
        .addClass 'text-ipter'
        .val @text.replace /<br\/>/g, "\n"
        .css
          'width': t_width
          'height': t_height
      .appendTo @$el
      .select()
      .focus()

    @fsm.onleaveediting_text = =>
      @$el.removeClass 'editing-text'
      @$text_ipter.remove()

      # 获取 textarea 中的文字，写入节点 dom
      @set_text @get_text_ipter_text()

    @fsm.onenteractive = =>
      @$el.addClass('active')

    @fsm.onleaveeactive = =>
      @$el.removeClass('active')


  # 设置节点文字
  set_text: (text)->
    @$text.html text
    @text = text


  # 在节点编辑状态下时获取 textarea 中的文本
  get_text_ipter_text: ->
    if @fsm.is 'editing_text'
      return @$text_ipter.val().replace /\n/g, '<br/>'

  adjust_text_ipter_size: ->
    text = @get_text_ipter_text()
    @$text.html text
    width = @$text.width()
    height = @$text.height()

    @$text_ipter.css
      'width': width
      'height': height

  render: ->
    $el = jQuery '<div>'
      .addClass 'idea'
      .data 'id', @id

    $text = jQuery '<div>'
      .addClass 'text'
      .html @text
      .appendTo $el

    @$el = $el
    @$text = $text

    return $el

  # 计算节点的尺寸，便于其他计算使用
  size: ->
    width = @$el.outerWidth()
    height = @$el.outerHeight()

    return {
      width: width
      height: height
    }

  # 将节点定位到编辑器的指定相对位置
  pos: (left, top, is_animate)->
    if is_animate
      @$el.animate
        left: left
        top: top
      , ANIMATE_DURATION
    else
      @$el.css
        left: left
        top: top

  # 开始编辑节点文字
  edit_text: ->
    console.log "开始编辑节点 #{@id} 文字：#{@text}"
    @fsm.edit_text()

  # 结束节点文字编辑
  stop_edit_text: ->
    console.log "结束节点文字编辑"
    @fsm.stop_edit_text()

  select: ->
    @fsm.select()

  # 判断节点是否被选中
  is_active: ->
    return @fsm.is 'active'

window.Idea = Idea
window.Utils = Utils