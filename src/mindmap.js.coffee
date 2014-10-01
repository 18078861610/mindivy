class BasicLayout
  constructor: (@mindmap)->
    @IDEA_Y_PADDING = 10
    @IDEA_X_PADDING = 30

  go: ->
    root_topic = @mindmap.root_topic

    # # 第一次遍历：求出所有节点的区域高度
    # # 区域高度的含义是，容纳节点及其所有子孙节点的区域的高度
    # @_layout_r1 root_topic

    # 第二次遍历：定位所有节点
    root_topic.pos 0, 0
    @_layout_r root_topic

  _layout_r: (topic)->
    mid_y = topic.layout_top + topic.layout_height / 2.0
    children_top = mid_y - topic.layout_children_height / 2.0
    children_left = topic.layout_left + topic.size().width + @IDEA_X_PADDING

    t = children_top
    for child_topic in topic.children
      left = children_left
      top = t + (child_topic.layout_area_height - child_topic.layout_height) / 2.0
      child_topic.pos left, top
      @_layout_r child_topic

      t += child_topic.layout_area_height + @IDEA_Y_PADDING

  calc_area_height: (topic)->
    topic.layout_children_height = 0

    for child_topic in topic.children
      # 如果还有没有初始化 dom 的子节点，则返回
      # return if not child_topic.rendered
      topic.layout_children_height += child_topic.layout_area_height

    console.log topic.layout_children_height

    topic.layout_children_height += @IDEA_X_PADDING * (topic.children.length - 1)
    topic.layout_area_height = Math.max topic.layout_height, topic.layout_children_height

    console.log topic.layout_area_height


class Mindmap
  constructor: (@$el)->
    @$topics_area = @$el.find('.topics-area')
    @basic_layout = new BasicLayout @

    @bind_topics_events()

  init: ->
    @root_topic = Topic.generate_root @
    return @

  # 每次增加节点后调用此方法
  # 调用此方法之前新增节点的 dom 不会被创建
  # 可以在批量创建节点后调用此方法
  render: ->
    Topic.each (id, topic)=>
      topic.render()
    @layout()
    return @

  # 重新对所有节点布局
  layout: ->
    @basic_layout.go()


  # 使得指定的节点在编辑器界面内居中显示
  center_to: (topic, is_animate)->


  # 在选择的节点上新增子节点
  insert_topic: ->
    if not @active_topic
      console.log '没有选中任何节点，无法增加子节点'
      return

    @add @active_topic.insert_topic()
    @render()


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
      switch evt.keyCode
        when 32
          evt.preventDefault()
          @active_topic.handle_space_keypress()


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

  mindmap.render()



  # 设置工具按钮操作事件
  # 导图居中显示
  mindmap.$el.delegate '.ops a.op.center', 'click', =>
    mindmap.center_to mindmap.root_topic, true

  mindmap.$el.delegate '.ops a.op.insert-topic', 'click', =>
    mindmap.insert_topic()


window.Mindmap = Mindmap
window.ANIMATE_DURATION = 200