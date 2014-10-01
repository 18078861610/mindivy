class Mindmap
  constructor: (@$el)->
    @IDEA_Y_PADDING = 10
    @IDEA_X_PADDING = 30

    @$topics_area = @$el.find('.topics-area')

    @topics = {}
    @bind_topics_events()


  init: ->
    @root_topic = new Topic('root', @)
    @add @root_topic
    return @

  render: ->
    for id, topic of @topics
      @$topics_area.append topic.render() if not topic.rendered
    @center_to @root_topic

    @layout()

    return @

  # 重新对所有节点布局
  layout: ->
    # 第一次遍历：求出所有节点的区域高度
    # 区域高度的含义是，容纳节点及其所有子孙节点的区域的高度
    @_layout_r1 @root_topic

    # for id, topic of @topics
    #   console.log id, topic.area_height

    # 第二次遍历：定位所有节点
    @root_topic.pos 0, 0
    @_layout_r2 @root_topic

  _layout_r1: (topic)->
    topic.children_height = 0
    for child_topic in topic.children
      topic.children_height += @_layout_r1 child_topic

    topic.children_height += @IDEA_Y_PADDING * (topic.children.length - 1)

    topic.this_height = topic.size().height
    topic.area_height = Math.max topic.this_height, topic.children_height

  _layout_r2: (topic)->
    mid_y = topic.layout_top + topic.this_height / 2.0
    children_top = mid_y - topic.children_height / 2.0
    children_left = topic.layout_left + topic.size().width + @IDEA_X_PADDING

    t = children_top
    for child_topic in topic.children
      left = children_left
      top = t + (child_topic.area_height - child_topic.this_height) / 2.0
      child_topic.pos left, top
      @_layout_r2 child_topic

      t += child_topic.area_height + @IDEA_Y_PADDING


  add: (topic)->
    @topics[topic.id] = topic

  get: (topic_id)->
    return @topics[topic_id]

  # 使得指定的节点在编辑器界面内居中显示
  center_to: (topic, is_animate)->
    # editor_size = @get_editor_size()
    # editor_width = editor_size.width
    # editor_height = editor_size.height

    # topic_size = topic.size()
    # topic_width = topic_size.width
    # topic_height = topic_size.height

    # # console.log editor_width, editor_height, topic_width, topic_height

    # topic_left = (editor_width - topic_width) / 2
    # topic_top  = (editor_height - topic_height) / 2

    # topic.pos(topic_left, topic_top, is_animate)

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
      topic = that.get jQuery(this).data('id')
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

  mindmap.add mindmap.root_topic.insert_topic()
  mindmap.add mindmap.root_topic.insert_topic()
  mindmap.add mindmap.root_topic.insert_topic()
  mindmap.add mindmap.root_topic.insert_topic()
  
  mindmap.add mindmap.root_topic.children[0].insert_topic()
  mindmap.add mindmap.root_topic.children[0].insert_topic()

  mindmap.add mindmap.root_topic.children[2].insert_topic()
  mindmap.add mindmap.root_topic.children[2].insert_topic()
  mindmap.add mindmap.root_topic.children[2].insert_topic()

  mindmap.add mindmap.root_topic.children[2].children[2].insert_topic()
  mindmap.add mindmap.root_topic.children[2].children[2].insert_topic()


  mindmap.render()



  # 设置工具按钮操作事件
  # 导图居中显示
  mindmap.$el.delegate '.ops a.op.center', 'click', =>
    mindmap.center_to mindmap.root_topic, true

  mindmap.$el.delegate '.ops a.op.insert-topic', 'click', =>
    mindmap.insert_topic()


window.Mindmap = Mindmap
window.ANIMATE_DURATION = 200