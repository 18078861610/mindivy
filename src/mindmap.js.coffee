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

    @$el.delegate '.topic .joint', 'click', (evt)->
      evt.stopPropagation()
      topic = Topic.get jQuery(this).closest('.topic').data('id')
      topic.handle_joint_click()
      
      
    # 点击节点外区域
    @$el.delegate '.bottom-area', 'click', (evt)=>
      @active_topic.handle_click_out() if @active_topic


    # 节点文字编辑框的键盘响应
    @$el.delegate '.topic textarea.text-ipter', 'keydown', (evt)=>
      @active_topic.text_ipter.handle_keydown(evt) if @active_topic

    
    # 全局按键事件
    jQuery(document).on 'keydown', (evt)=>
      console.log "keyCode: " + evt.keyCode

      if @active_topic  
        switch evt.keyCode
          when 32 # spacebar
            evt.preventDefault()
            @active_topic.handle_space_keydown()
          when 45 # insert
            evt.preventDefault()
            @active_topic.handle_insert_keydown()
          when 13 # enter
            evt.preventDefault()
            @active_topic.handle_enter_keydown()
          when 46 # delete
            evt.preventDefault()
            @active_topic.handle_delete_keydown()
          when 38 # ↑
            evt.preventDefault()
            @active_topic.handle_arrow_keydown('up')
          when 40 # ↓
            evt.preventDefault()
            @active_topic.handle_arrow_keydown('down')
          when 37 # ←
            evt.preventDefault()
            @active_topic.handle_arrow_keydown('left')
          when 39 # →
            evt.preventDefault()
            @active_topic.handle_arrow_keydown('right')

        if evt.keyCode is 73 and evt.shiftKey
          # console.log '打开添加图片对话框'
          evt.preventDefault()
          @active_topic.open_image_dialog()


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

  mindmap.root_topic.children[1]
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[1].children[1]
    .insert_topic()
    .insert_topic()


  mindmap.root_topic.children[2]
    .insert_topic()
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[2].children[1]
    .insert_topic()
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[2].children[2]
    .insert_topic()
    .insert_topic()
    .insert_topic()
    .insert_topic()
    .insert_topic()
    .insert_topic()
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[0].children[0]
    .insert_topic()
    .insert_topic()

  mindmap.root_topic.children[3]
    .insert_topic()

  mindmap.root_topic.children[3].children[0]
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