class ImageDialog
  constructor: (@topic)->
    @img_url = @topic.img_url

  render: ->
    @$overlay = jQuery '<div>'
      .addClass 'image-dialog-overlay'
      .appendTo @topic.mindmap.$el

    @$dialog = jQuery '<div>'
      .addClass 'image-dialog'
      .appendTo @topic.mindmap.$el


    $ops = jQuery '<div>'
      .addClass 'image-dialog-ops'
      .appendTo @$dialog


    @$ok = jQuery '<div>'
      .addClass 'btn ok'
      .html '确定'
      .appendTo $ops

    @$cancel = jQuery '<div>'
      .addClass 'btn cancel'
      .html '取消'
      .appendTo $ops


    @$delete = jQuery '<div>'
      .addClass 'btn delete'
      .html '删除图片'
      .appendTo $ops


    @$url_ipter = jQuery '<input>'
      .attr 'type', 'text'
      .attr 'placeholder', '输入图片 URL'
      .addClass 'url-ipter'
      .appendTo @$dialog

    @$image_loading_area = jQuery '<div>'
      .addClass 'image-loading-area'
      .appendTo @$dialog

    if @img_url
      @$url_ipter.val @img_url
      @_show_img @img_url

    @bind_events()

  bind_events: ->
    @$overlay.on 'click', (evt)=>
      @destroy()

    @$cancel.on 'click', (evt)=>
      @destroy()

    @$url_ipter.on 'input', (evt)=>
      url = @$url_ipter.val()
      @_show_img url

    @$ok.on 'click', (evt)=>
      url = @$url_ipter.val()
      @topic.set_image_url url
      @destroy()

    @$delete.on 'click', (evt)=>
      @topic.set_image_url null
      @destroy()

  destroy: ->
    @$overlay.remove()
    @$dialog.remove()

  _show_img: (url)->
    @$image_loading_area
      .css 'background-image', "url(#{url})"


class TextInputer
  constructor: (@topic)->
    @$topic_text = @topic.$text
    @render()

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


ModuleTopicNav =
  # 判断是否是根节点
  is_root: ->
    return @depth is 0

  # 获取当前节点的下一个同级节点，如果没有的话，返回 null
  next: ->
    return null if @is_root()
    idx = @parent.children.indexOf @
    return @parent.children[idx + 1]

  # 返回当前节点的上一个同级节点，如果没有的话，返回 null
  prev: ->
    return null if @is_root()
    idx = @parent.children.indexOf @
    return @parent.children[idx - 1]

  # 找到同级的上一个节点，不管是不是同一个父节点
  # 需要结合节点的折叠状态来判断
  visible_prev: ->
    return null if @is_root()
    return @prev() if @prev()

    p = @parent
    while p = p.visible_prev()
      return p.last_child() if p.has_children() and p.is_opened()

    return null

  # 找到同级的下一个节点，不管是不是同一个父节点
  # 需要结合节点的折叠状态来判断
  visible_next: ->
    return null if @is_root()
    return @next() if @next()

    p = @parent
    while p = p.visible_next()
      return p.first_child() if p.has_children() and p.is_opened()

    return null

  # 第一个子节点，如果没有子节点，返回 null
  first_child: ->
    return @children[0]

  # 最后一个子节点，如果没有子节点，返回 null
  last_child: ->
    return @children[@children.length - 1]

  # 判断该子节点是否有子节点
  has_children: ->
    !!@children.length


ModuleTopicState =
  is_opened: ->
    return @oc_fsm.is 'opened'

  is_closed: ->
    return @oc_fsm.is 'closed'


class Topic extends Module
  @include ModuleTopicNav
  @include ModuleTopicState

  @HASH: {}

  @ROOT_TOPIC_TEXT : 'Central Topic'
  @LV1_TOPIC_TEXT  : 'Main Topic'
  @LV2_TOPIC_TEXT  : 'Subtopic'

  @STATES: ['common', 'active', 'editing']

  # 创建根节点
  @generate_root: (mindmap)->
    root = new Topic @ROOT_TOPIC_TEXT, mindmap
    root.depth = 0
    @set root
    return root

  # 将指定节点存入 hash
  @set: (topic)->
    @HASH[topic.id] = topic

  @get: (id)->
    @HASH[id]

  @each: (func)->
    for id, topic of @HASH
      func(id, topic)

  constructor: (@text, @mindmap)->
    @init_fsm()
    @init_open_close_fsm()

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
      @text_ipter = new TextInputer(@)


    @fsm.onleaveediting = =>
      @mindmap.editing_topic = null
      @$el.removeClass 'editing'

      @set_text @text_ipter.text()
      @text_ipter.destroy()
      delete @text_ipter

      @recalc_size()
      @mindmap.layout()


  init_open_close_fsm: ->
    @oc_fsm = StateMachine.create
      initial: 'opened'
      events: [
        { name: 'open',  from: 'closed', to: 'opened'}
        { name: 'close', from: 'opened', to: 'closed'}
      ]

    @oc_fsm.onenteropened = =>
      @$el.addClass 'opened'

    @oc_fsm.onleaveopened = =>
      @$el.removeClass 'opened'

    @oc_fsm.onenterclosed = =>
      @$el.addClass 'closed'

    @oc_fsm.onleaveclosed = =>
      @$el.removeClass 'closed'

    _open_r = (topic)=>
      for child in topic.children
        child.$el.show()
        
        continue if child.is_closed()
        child.$canvas.show() if child.$canvas
        _open_r child

    @oc_fsm.onbeforeopen = =>
      console.log '展开子节点'
      @$canvas.show()
      _open_r @

    _close_r = (topic)=>
      for child in topic.children
        child.$el.hide()
        # 当节点被折叠时，解除 active 状态
        child.fsm.stop_edit() if child.fsm.can 'stop_edit'
        child.fsm.unselect() if child.fsm.can 'unselect'

        continue if child.is_closed()
        child.$canvas.hide() if child.$canvas
        _close_r child

    @oc_fsm.onbeforeclose = =>
      console.log '折叠子节点'
      @$canvas.hide()
      _close_r @


  # 设置节点文字
  set_text: (text)->
    @$text.text text
    @text = text


   # 输入文字的同时动态调整 textarea 的大小
  adjust_text_ipter_size: ->
    @text_ipter._adjust_text_ipter_size()


  # 闪烁动画
  flash_animate: ->
    @$el
      .addClass 'flash-highlight'

    setTimeout =>
      @$el.removeClass 'flash-highlight'
    , 500

    # 增加节点时，父节点显示 +1 效果
    $float_num = jQuery '<div>'
      .addClass 'float-num'
      .addClass 'plus'
      .html '+1'
      .appendTo @parent.$el

      .animate
        'top': '-=20'
        'opacity': '0'
      , 600, ->
        $float_num.remove()


  # 生成节点 dom 只会调用一次
  render: ->
    if not @rendered
      @rendered = true

      # 当前节点 dom
      @$el = jQuery '<div>'
        .addClass 'topic'
        .addClass 'opened'
        .data 'id', @id

      @$el.addClass 'root' if @is_root()

      # 节点上的图片
      @$image = jQuery '<div>'
        .addClass 'image'
        .appendTo @$el

      # 节点上的文字
      @$text = jQuery '<pre>'
        .addClass 'text'
        .text @text
        .appendTo @$el

      # 折叠展开的操作区域
      @$joint = jQuery '<div>'
        .addClass 'joint'
        .appendTo @$el

      @$el.appendTo @mindmap.$topics_area

      if @flash
        @flash_animate()

    # 标记叶子节点
    if @has_children()
      @$el.removeClass 'leaf'
    else
      @$el.addClass 'leaf'

    # 显示图片
    if @img_url
      @$el.addClass 'with-image'
      @$image.css 'background-image', "url(#{@img_url})"
    else
      @$el.removeClass 'with-image'

    # 根据节点是左侧节点还是右侧节点，给予相应的 className
    @$el.removeClass('left-side').removeClass('right-side')
    @$el.addClass('left-side')  if @side is 'left'
    @$el.addClass('right-side') if @side is 'right'


    # 重新计算尺寸
    @recalc_size()

    return @$el


  # 重新计算节点布局宽高
  recalc_size: ->
    @layout_width  = @$el.outerWidth()
    @layout_height = @$el.outerHeight()


  # 计算节点的尺寸，便于其他计算使用
  size: ->
    return {
      width: @layout_width
      height: @layout_height
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
  # options
  #   flash: 新增节点时是否有闪烁效果
  #   after: 新增的节点在哪个同级节点的后面，如果不传的话默认最后一个

  # 如果当前节点是根节点：
  #   当左边的一级子节点较多（或相等），新增的一级子节点排在右边
  #   当右边的一级子节点较多，新增的一级子节点排在左边

  insert_topic: (options)->
    options ||= {}
    flash = options.flash
    after = options.after

    if @is_root()
      text = Topic.LV1_TOPIC_TEXT
    else
      text = Topic.LV2_TOPIC_TEXT

    child_topic = new Topic text, @mindmap
    child_topic.depth = @depth + 1
    child_topic.flash = flash

    if @is_root()
      c_left  = @left_children().length
      c_right = @right_children().length

      # console.log "left: #{c_left}, right: #{c_right}"

      if c_left >= c_right
        child_topic.side = 'right'
      else
        child_topic.side = 'left'

    if after is undefined
      @children.push child_topic
    else
      arr0 = @children[0..after]
      arr1 = @children[after + 1..@children.length]
      @children = (arr0.concat [child_topic]).concat arr1
      console.log @children

    child_topic.parent = @

    Topic.set child_topic
    return @


  # 返回根节点上的左侧子节点数组
  left_children: ->
    return (child for child in @children when child.side is 'left')

  # 返回根节点上的右侧子节点数组
  right_children: ->
    return (child for child in @children when child.side is 'right')


  # 删除当前节点以及所有子节点
  delete_topic: ->
    # 删除节点后，重新定位当前的 active_topic
    # 如果有后续同级节点，选中后续同级节点
    # 如果有前置同级节点，选中前置同级节点
    if @next()
      console.log @next()
      @next().fsm.select()
    else if @prev()
      @prev().fsm.select()
    else
      @parent.fsm.select()


    # 删除 dom
    # 遍历，清除所有子节点 dom
    @_delete_r @
    # 清除父子关系
    parent_children = @parent.children
    idx = parent_children.indexOf @
    arr0 = parent_children[0 ... idx]
    arr1 = parent_children[idx + 1 .. -1]
    parent_children = arr0.concat arr1
    @parent.children = parent_children
    console.log arr0, arr1, @parent.children

    if @parent.children.length is 0
      @parent.$canvas.remove()

    # 删除节点时，父节点显示 -1 效果
    $pel = @parent.$el

    $float_num = jQuery '<div>'
      .addClass 'float-num'
      .addClass 'minus'
      .html '-1'
      .appendTo $pel.css 'z-index', '2'

      .animate
        'bottom': '-=20'
        'opacity': '0'
      , 600, =>
        $float_num.remove()
        $pel.css 'z-index', ''
    
    @parent = null


  _delete_r: (topic)->
    for child in topic.children
      @_delete_r child

    topic.$canvas.remove() if topic.$canvas
    topic.$el.remove()


  # 处理节点点击事件
  handle_click: ->
    return @fsm.select() if @fsm.can 'select'
    return @fsm.start_edit() if @fsm.can 'start_edit'

  # 处理节点折叠点点击事件
  handle_joint_click: ->
    if @is_closed()
      @oc_fsm.open()
    else if @is_opened()
      @oc_fsm.close()
    @mindmap.layout()


  # 处理节点外点击事件
  handle_click_out: ->
    @fsm.stop_edit() if @fsm.can 'stop_edit'
    @fsm.unselect() if @fsm.can 'unselect'


  # 处理空格按下事件
  handle_space_keydown: ->
    @fsm.start_edit() if @fsm.can 'start_edit'


  # 处理 insert 按键按下事件
  handle_insert_keydown: ->
    return if not @fsm.is 'active'

    @insert_topic {flash: true}
    @mindmap.layout()
    @children[@children.length - 1].fsm.select()

  # 处理回车键按下事件
  handle_enter_keydown: ->
    return if not @fsm.is 'active'

    if @is_root()
      @insert_topic {flash: true}
      @mindmap.layout()
      return

    @parent.insert_topic {
      flash: true
      after: @parent.children.indexOf @
    }
    @mindmap.layout()
    @next().fsm.select()


  # 处理 delete 键按下事件
  handle_delete_keydown: ->
    return if not @fsm.is 'active'

    if not @is_root()
      @delete_topic()
      @mindmap.layout()

  handle_arrow_keydown: (direction)->
    switch direction
      when 'up'
        topic = @visible_prev()
        topic.fsm.select() if topic

      when 'down'
        topic = @visible_next()
        topic.fsm.select() if topic

      when 'left'
        @parent.fsm.select() if @parent

      when 'right'
        if @is_opened() 
          if length = @children.length
            idx = ~~((length - 1) / 2)
            if child = @children[idx]
              child.fsm.select()


  open_image_dialog: ->
    new ImageDialog(@).render()

  # 根据 url 设置节点图片，如果传入的值是 null，则去除图片
  set_image_url: (url)->
    @img_url = url
    @mindmap.layout()


window.Topic = Topic
window.Utils = Utils