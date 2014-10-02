class BasicLayout
  constructor: (@mindmap)->
    @IDEA_Y_PADDING = 10
    @IDEA_X_PADDING = 30

  go: ->
    root_topic = @mindmap.root_topic

    # 第一次遍历：深度优先遍历
    # 渲染所有节点并且计算各个节点的布局数据
    @_layout_r1 root_topic

    # 第二次遍历：宽度优先遍历
    # 定位所有节点
    root_topic.pos 0, 0
    @_layout_r2 root_topic

  _layout_r1: (topic)->
    layout_children_height = 0

    for child in topic.children
      @_layout_r1 child
      layout_children_height += child.layout_area_height
    layout_children_height += @IDEA_Y_PADDING * (topic.children.length - 1)
    
    topic.layout_children_height = layout_children_height
    topic.render() # 生成 dom，同时计算 topic.layout_height
    topic.layout_area_height = Math.max topic.layout_height, layout_children_height


  _layout_r2: (topic)->
    mid_y = topic.layout_top + topic.layout_height / 2.0
    layout_children_top = mid_y - topic.layout_children_height / 2.0
    layout_children_left = topic.layout_left + topic.size().width + @IDEA_X_PADDING

    t = layout_children_top
    for child in topic.children
      left = layout_children_left
      top  = t + (child.layout_area_height - child.layout_height) / 2.0
      child.pos left, top
      @_layout_r2 child

      t += child.layout_area_height + @IDEA_Y_PADDING


    topic.layout_children_top = layout_children_top
    topic.layout_children_left = layout_children_left


  draw_lines: ->
    console.log '开始画线'
    root_topic = @mindmap.root_topic
    @_d_r root_topic


  _d_r: (topic)->
    if topic.has_children()
      # 如果当前节点有子节点，则创建针对该子节点的 canvas 图层
      ctx = @_init_canvas_on topic
      for child in topic.children
        # 每个子节点画一条曲线
        @_draw_line topic, child, ctx
        @_d_r child

  _init_canvas_on: (topic)->
    left   = topic.layout_left # 当前节点的左边缘
    top    = topic.layout_children_top # 所有子节点的上边缘
    right  = topic.layout_children_left + 50 # 所有子节点的左边缘，向右偏移 50px
    bottom = top + topic.layout_children_height # 所有子节点的下边缘

    width = right - left
    height = bottom - top

    if not topic.$canvas
      topic.$canvas = jQuery '<canvas>'

    topic.$canvas
      .css
        'left': left
        'top': top
        'width': width
        'height': height
      .attr
        'width': width
        'height': height
      .appendTo @mindmap.$topics_area    

    ctx = topic.$canvas[0].getContext '2d'
    ctx.clearRect 0, 0, width, height
    ctx.translate -left, -top

    return ctx

  _draw_line: (parent, child, ctx)->
    # 在父子节点之间绘制连线
    if parent.depth is 0
      @_draw_line_0 parent, child, ctx
      return

    @_draw_line_n parent, child, ctx

  # 在根节点上绘制曲线
  _draw_line_0: (parent, child, ctx)->
    # 绘制贝塞尔曲线
    # 两个端点
    # 父节点的中心点
    x0 = parent.layout_left + parent.layout_width / 2.0
    y0 = parent.layout_top  + parent.layout_height / 2.0

    # 子节点的左侧中点
    x1 = child.layout_left
    y1 = child.layout_top + child.layout_height / 2.0

    # 两个控制点
    xc1 = x0 + 30 
    yc1 = y0

    xc2 = (x0 + x1) / 2.0
    yc2 = y1 

    ctx.lineWidth = 2
    ctx.strokeStyle = '#666'

    ctx.beginPath()
    ctx.moveTo x0, y0
    ctx.bezierCurveTo xc1, yc1, xc2, yc2, x1, y1 
    ctx.stroke()

  _draw_line_n: (parent, child, ctx)->
    # 绘制贝塞尔曲线
    # 两个端点
    # 父节点的右侧中点
    x0 = parent.layout_left + parent.layout_width
    y0 = parent.layout_top  + parent.layout_height / 2.0

    # 子节点的左侧中点
    x1 = child.layout_left
    y1 = child.layout_top + child.layout_height / 2.0

    # 两个控制点
    xc1 = (x0 + x1) / 2.0
    yc1 = y0

    xc2 = xc1
    yc2 = y1

    ctx.lineWidth = 2
    ctx.strokeStyle = '#666'

    ctx.beginPath()
    ctx.moveTo x0, y0
    ctx.bezierCurveTo xc1, yc1, xc2, yc2, x1, y1 
    ctx.stroke()


class Mindmap
  constructor: (@$el)->
    @$topics_area = @$el.find('.topics-area')
    @basic_layout = new BasicLayout @

    @bind_topics_events()

  init: ->
    @root_topic = Topic.generate_root @
    return @

  # 重新对所有节点布局
  # 增加或修改节点后调用此方法
  layout: ->
    @basic_layout.go()
    @basic_layout.draw_lines()


  # 使得指定的节点在编辑器界面内居中显示
  center_to: (topic, is_animate)->


  # 在选择的节点上新增子节点
  insert_topic: ->
    if not @active_topic
      console.log '没有选中任何节点，无法增加子节点'
      return

    @active_topic.insert_topic()
    @layout()


  get_editor_size: ->
    width = @$el.width()
    height = @$el.height()

    return {
      width: width
      height: height
    }


  # 设置导图节点事件
  bind_topics_events: ->
    that = this

    # 单击节点
    @$el.delegate '.topic', 'click', (evt)->
      evt.stopPropagation()
      topic = Topic.get jQuery(this).data('id')
      topic.handle_click()
      
      
    # 点击节点外区域
    @$el.delegate '.bottom-area', 'click', (evt)=>
      @active_topic.handle_click_out() if @active_topic


    # 节点文字编辑框的键盘响应
    @$el.delegate '.topic textarea.text-ipter', 'keydown', (evt)=>
      @active_topic.text_ipter.handle_keydown(evt) if @active_topic

    
    # 全局按键事件
    jQuery(document).on 'keydown', (evt)=>
      console.log "keyCode: " + evt.keyCode
      switch evt.keyCode
        when 32 # spacebar
          evt.preventDefault()
          @active_topic.handle_space_keydown() if @active_topic
        when 45 # insert
          evt.preventDefault()
          @active_topic.handle_insert_keydown() if @active_topic
        when 13 # enter
          evt.preventDefault()
          @active_topic.handle_enter_keydown() if @active_topic


jQuery(document).ready ->
  mindmap = new Mindmap jQuery('.mindmap')
  mindmap.init()

  mindmap.root_topic
    .insert_topic()
    .insert_topic()
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[0]
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[2]
    .insert_topic()
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[2].children[2]
    .insert_topic()
    .insert_topic()

  mindmap.layout()



  # 设置工具按钮操作事件
  # 导图居中显示
  mindmap.$el.delegate '.ops a.op.center', 'click', =>
    mindmap.center_to mindmap.root_topic, true

  mindmap.$el.delegate '.ops a.op.insert-topic', 'click', =>
    mindmap.insert_topic()


window.Mindmap = Mindmap
window.ANIMATE_DURATION = 200