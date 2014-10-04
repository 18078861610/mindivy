class BasicLayout
  constructor: (@mindmap)->
    @IDEA_Y_PADDING = 10
    @IDEA_X_PADDING = 30
    @JOINT_WIDTH = 16 # 折叠点的宽度

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

    # 如果不是一级子节点/根节点，根据父节点的 side 来为当前节点的 side 赋值
    if topic.depth > 1
      topic.side = topic.parent.side

    # 如果是根节点，分成左右两侧计算布局数据
    if topic.is_root()
      layout_left_children_height = 0
      layout_right_children_height = 0

      for child in topic.right_children()
        @_layout_r1 child
        layout_right_children_height += child.layout_area_height
      layout_right_children_height += @IDEA_Y_PADDING * (topic.right_children().length - 1)


      for child in topic.left_children()
        @_layout_r1 child
        layout_left_children_height += child.layout_area_height
      layout_left_children_height += @IDEA_Y_PADDING * (topic.left_children().length - 1)

      topic.layout_left_children_height = layout_left_children_height
      topic.layout_right_children_height = layout_right_children_height
      topic.render()

      return

    
    layout_children_height = 0
    if topic.is_opened()
      for child in topic.children
        @_layout_r1 child
        layout_children_height += child.layout_area_height
      layout_children_height += @IDEA_Y_PADDING * (topic.children.length - 1)
    
    topic.layout_children_height = layout_children_height
    topic.render() # 生成 dom，同时计算 topic.layout_height
    topic.layout_area_height = Math.max topic.layout_height, layout_children_height


  _layout_r2: (topic)->
    mid_y = topic.layout_top + topic.layout_height / 2.0

    # 右侧
    layout_right_children_top  = mid_y - topic.layout_right_children_height / 2.0
    layout_right_children_left = topic.layout_left + topic.layout_width + @IDEA_X_PADDING

    t = layout_right_children_top
    for child in topic.right_children()
      left = layout_right_children_left
      top  = t + (child.layout_area_height - child.layout_height) / 2.0
      child.pos left, top
      @_layout_r2_right child

      t += child.layout_area_height + @IDEA_Y_PADDING


    # 左侧
    layout_left_children_top   = mid_y - topic.layout_left_children_height / 2.0
    layout_left_children_right = topic.layout_left - @IDEA_X_PADDING

    t = layout_left_children_top
    for child in topic.left_children()
      left = layout_left_children_right - child.layout_width
      top = t + (child.layout_area_height - child.layout_height) / 2.0
      child.pos left, top
      @_layout_r2_left child

      t += child.layout_area_height + @IDEA_Y_PADDING


  # 针对左侧子节点的遍历
  _layout_r2_left: (topic)->
    mid_y = topic.layout_top + topic.layout_height / 2.0
    layout_children_top = mid_y - topic.layout_children_height / 2.0
    layout_children_right = topic.layout_left - @IDEA_X_PADDING

    t = layout_children_top
    for child in topic.children
      left = layout_children_right - topic.layout_width
      top  = t + (child.layout_area_height - child.layout_height) / 2.0
      child.pos left, top
      @_layout_r2_left child

      t += child.layout_area_height + @IDEA_Y_PADDING

    topic.layout_children_top = layout_children_top
    topic.layout_children_right = layout_children_right


  # 针对右侧子节点的遍历
  _layout_r2_right: (topic)->
    mid_y = topic.layout_top + topic.layout_height / 2.0
    layout_children_top = mid_y - topic.layout_children_height / 2.0
    layout_children_left = topic.layout_left + topic.size().width + @IDEA_X_PADDING

    t = layout_children_top
    for child in topic.children
      left = layout_children_left
      top  = t + (child.layout_area_height - child.layout_height) / 2.0
      child.pos left, top
      @_layout_r2_right child

      t += child.layout_area_height + @IDEA_Y_PADDING

    topic.layout_children_top = layout_children_top
    topic.layout_children_left = layout_children_left

  draw_lines: ->
    # console.log '开始画线'
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
    x0 = parent.layout_left + parent.layout_width + @JOINT_WIDTH
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

window.BasicLayout = BasicLayout