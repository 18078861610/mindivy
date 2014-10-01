Utils =
  generate_id: ->
    str = 'abcdefghijklmnopqrstuvwxyz0123456789'
    l = str.length
    re = ''

    for i in [0...7]
      r = ~~(Math.random() * l)
      re = re + str[r]

    return re


class TextInputer
  constructor: (@topic)->
    @$topic_text = @topic.$text

  render: ->
    # 此区域用来给 textarea 提供背景色
    @$textarea_box = jQuery '<div>'
      .addClass 'text-ipter-box'
      .css
        'left': 0
        'bottom': 0
      .appendTo @topic.$el

    # 复制一个 text dom 用来计算高度
    @$text_measure = @$topic_text.clone()
      .css 
        'position': 'absolute'
        'display': 'none'
      .appendTo @$textarea_box

    # textarea 左下角固定
    @$textarea = jQuery '<textarea>'
      .addClass 'text-ipter'
      .css
        'left': 0
        'bottom': 0
      .val @topic.text
      .appendTo @$textarea_box
      .select()
      .focus()

    @_copy_text_size()
    return @

  # 获取 textarea 中的值，并进行必要的转换
  text: ->
    # 把末尾的换行符添加一个空格，以便于 pre 自适应高度
    @$textarea.val().replace /\n$/, "\n "

  destroy: ->
    @$textarea_box.remove()

  _adjust_text_ipter_size: ->
    setTimeout =>
      @$text_measure.text @text()
      @_copy_text_size()

  # 将 text pre dom 的宽高复制给 textarea 和它的外框容器
  _copy_text_size: ->
    [w, h] = [@$text_measure.width(), @$text_measure.height()]

    # 记录初始宽高值，使得编辑节点内容时，编辑框的宽高不会小于初始值
    # 目前不确定是否需要这个体验特性，先注释掉
    # if not @$textarea_box.data 'origin-width'
    #   @$textarea_box.data 'origin-width', w
    #   @$textarea_box.data 'origin-height', h
    # else
    #   w = Math.max w, @$textarea_box.data 'origin-width'
    #   h = Math.max h, @$textarea_box.data 'origin-height'

    @$textarea_box.css
      'width':  w
      'height': h

    @$textarea.css
      'width':  w
      'height': h

  # 响应键盘事件
  # 为了执行效率和节约内存，事件绑定使用全局的 delegate
  handle_keydown: (evt)->
    # 停止冒泡，防止触发全局快捷键
    evt.stopPropagation()
    
    # 调整 textarea 大小
    @_adjust_text_ipter_size()

    if evt.keyCode is 13 and not evt.shiftKey
      # 按下回车时，结束编辑，保存当前文字，阻止原始的回车事件
      evt.preventDefault()
      @topic.fsm.stop_edit()
    else
      # 按下 shift + 回车时，换行
      # do nothing 执行 textarea 原始事件


class Topic
  @ROOT_TOPIC_TEXT : 'Central Topic'
  @LV1_TOPIC_TEXT  : 'Main Topic'
  @LV2_TOPIC_TEXT  : 'Subtopic'

  @STATES: ['common', 'active', 'editing']

  # 创建根节点
  @generate_root: (mindmap)->
    root = new Topic @ROOT_TOPIC_TEXT, mindmap
    root.depth = 0
    return root

  constructor: (@text, @mindmap)->
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
      if @mindmap.active_topic and @mindmap.active_topic != @
        @mindmap.active_topic.handle_click_out()

      @mindmap.active_topic = @
      @$el.addClass('active')

    @fsm.onbeforeunselect = =>
      @mindmap.active_topic = null
      @$el.removeClass('active')


    # 切换与退出编辑状态
    @fsm.onenterediting = =>
      @mindmap.editing_topic = @
      @$el.addClass 'editing'

      @text_ipter = new TextInputer(@).render()


    @fsm.onleaveediting = =>
      @mindmap.editing_topic = null
      @$el.removeClass 'editing'

      @set_text @text_ipter.text()
      @text_ipter.destroy()
      delete @text_ipter

      @mindmap.layout()


  # 设置节点文字
  set_text: (text)->
    @$text.text text
    @text = text


   # 输入文字的同时动态调整 textarea 的大小
  adjust_text_ipter_size: ->
    @text_ipter._adjust_text_ipter_size()


  render: ->
    # 当前节点 dom
    @$el = jQuery '<div>'
      .addClass 'topic'
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


  # 在当前节点增加一个新的子节点
  insert_topic: ->
    console.log @depth

    if @depth is 0
      text = Topic.LV1_TOPIC_TEXT
    else
      text = Topic.LV2_TOPIC_TEXT

    child_topic = new Topic text, @mindmap
    child_topic.depth = @depth + 1

    @children.push child_topic
    @mindmap.add child_topic
    return @


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


window.Topic = Topic
window.Utils = Utils