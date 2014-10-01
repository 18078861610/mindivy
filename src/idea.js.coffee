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
  constructor: (@text, @mindmap)->
    # STATES = ['common', 'editing_text', 'active']
    @init_fsm()
    @id = Utils.generate_id()
    @children = []

  
  init_fsm: ->
    @fsm = StateMachine.create
      initial: 'common'
      events: [
        { name: 'select',   from: 'common', to: 'active'}
        { name: 'unselect', from: 'active', to: 'common'}

        { name: 'start_edit', from: 'active',  to: 'editing' }
        { name: 'stop_edit',  from: 'editing', to: 'active' }
      ]

    # 切换与退出选中状态
    @fsm.onbeforeselect = =>
      if @mindmap.active_idea and @mindmap.active_idea != @
        @mindmap.active_idea.handle_click_out()

      @mindmap.active_idea = @
      @$el.addClass('active')

    @fsm.onbeforeunselect = =>
      @mindmap.active_idea = null
      @$el.removeClass('active')


    # 切换与退出编辑状态
    @fsm.onenterediting = =>
      @mindmap.editing_idea = @
      @$el.addClass 'editing'

      # 计算 textarea 的初始大小
      t_width  = @$text.width()
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


    @fsm.onleaveediting = =>
      @mindmap.editing_idea = null
      @$el.removeClass 'editing'

      @$text_ipter.remove()

      # 获取 textarea 中的文字，写入节点 dom
      @set_text @get_text_ipter_text()


  # 设置节点文字
  set_text: (text)->
    @$text.text text
    @text = text


  # 在节点编辑状态下时获取 textarea 中的文本
  get_text_ipter_text: ->
    if @fsm.is 'editing'
      return @$text_ipter.val().replace /\n$/, "\n "


   # 输入文字的同时动态调整 textarea 的大小
  adjust_text_ipter_size: ->
    setTimeout =>
      text = @get_text_ipter_text()
      @$text.text text

      width = @$text.width()
      height = @$text.height()

      @$text_ipter.css
        'width': width
        'height': height

  render: ->
    # 当前节点 dom
    @$el = jQuery '<div>'
      .addClass 'idea'
      .data 'id', @id

    # 节点上的文字
    @$text = jQuery '<pre>'
      .addClass 'text'
      .text @text
      .appendTo @$el

    @rendered = true

    return @$el

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
    @layout_left = left
    @layout_top = top

    if is_animate
      @$el.animate
        left: left
        top: top
      , ANIMATE_DURATION
    else
      @$el.css
        left: left
        top: top


  # 增加一个新的子节点
  insert_idea: ->
    child_idea = new Idea 'new idea', @mindmap
    @children.push child_idea
    child_idea


  # 处理节点点击事件
  handle_click: ->
    return @fsm.select() if @fsm.can 'select'
    return @fsm.start_edit() if @fsm.can 'start_edit'

  # 处理节点外点击事件
  handle_click_out: ->
    @fsm.stop_edit() if @fsm.can 'stop_edit'
    @fsm.unselect() if @fsm.can 'unselect'

  # 处理空格按下事件
  handle_space_keypress: ->
    @fsm.start_edit() if @fsm.can 'start_edit'

  handle_enter_keypress: ->
    @fsm.stop_edit() if @fsm.can 'stop_edit'


window.Idea = Idea
window.Utils = Utils