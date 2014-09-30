class Mindmap
  constructor: (@$el)->
    @IDEA_Y_PADDING = 10
    @IDEA_X_PADDING = 30

    @$ideas_area = @$el.find('.ideas-area')

    @ideas = {}
    @bind_ideas_events()


  init: ->
    @root_idea = new Idea('root', @)
    @add @root_idea
    return @

  render: ->
    for id, idea of @ideas
      @$ideas_area.append idea.render() if not idea.rendered
    @center_to @root_idea

    @layout()

    return @

  # 重新对所有节点布局
  layout: ->
    # 第一次遍历：求出所有节点的区域高度
    # 区域高度的含义是，容纳节点及其所有子孙节点的区域的高度
    @_layout_r1 @root_idea

    # for id, idea of @ideas
    #   console.log id, idea.area_height

    # 第二次遍历：定位所有节点
    @root_idea.pos 0, 0
    @_layout_r2 @root_idea

  _layout_r1: (idea)->
    idea.children_height = 0
    for child_idea in idea.children
      idea.children_height += @_layout_r1 child_idea

    idea.children_height += @IDEA_Y_PADDING * (idea.children.length - 1)

    idea.this_height = idea.size().height
    idea.area_height = Math.max idea.this_height, idea.children_height

  _layout_r2: (idea)->
    mid_y = idea.layout_top + idea.this_height / 2.0
    children_top = mid_y - idea.children_height / 2.0
    children_left = idea.layout_left + idea.size().width + @IDEA_X_PADDING

    t = children_top
    for child_idea in idea.children
      left = children_left
      top = t + (child_idea.area_height - child_idea.this_height) / 2.0
      child_idea.pos left, top
      @_layout_r2 child_idea

      t += child_idea.area_height + @IDEA_Y_PADDING


  add: (idea)->
    @ideas[idea.id] = idea

  get: (idea_id)->
    return @ideas[idea_id]

  # 使得指定的节点在编辑器界面内居中显示
  center_to: (idea, is_animate)->
    # editor_size = @get_editor_size()
    # editor_width = editor_size.width
    # editor_height = editor_size.height

    # idea_size = idea.size()
    # idea_width = idea_size.width
    # idea_height = idea_size.height

    # # console.log editor_width, editor_height, idea_width, idea_height

    # idea_left = (editor_width - idea_width) / 2
    # idea_top  = (editor_height - idea_height) / 2

    # idea.pos(idea_left, idea_top, is_animate)

  # 在选择的节点上新增子节点
  insert_idea: ->
    if not @active_idea
      console.log '没有选中任何节点，无法增加子节点'
      return

    @add @active_idea.insert_idea()
    @render()


  get_editor_size: ->
    width = @$el.width()
    height = @$el.height()

    return {
      width: width
      height: height
    }


  # 设置导图节点事件
  bind_ideas_events: ->
    that = this

    # 单击节点
    @$el.delegate '.idea', 'click', (evt)->
      evt.stopPropagation()
      idea = that.get jQuery(this).data('id')
      idea.handle_click()
      
      
    # 点击节点外区域
    @$el.delegate '.bottom-area', 'click', (evt)=>
      @active_idea.handle_click_out() if @active_idea


    # 节点文字编辑框的键盘响应
    @$el.delegate '.idea textarea.text-ipter', 'keydown', (evt)->
      # 停止冒泡，防止触发全局快捷键
      evt.stopPropagation()
      idea = that.get jQuery(this).closest('.idea').data('id')

      switch evt.keyCode
        when 13
          if not evt.shiftKey
            # 按下回车时，结束编辑，保存当前文字，阻止原始的回车事件
            evt.preventDefault()
            idea.handle_enter_keypress()
          else 
            # 按下 shift + 回车时，换行
            # do nothing 执行 textarea 原始事件
            idea.adjust_text_ipter_size()
        else
          idea.adjust_text_ipter_size()
              

    
    # 全局按键事件
    jQuery(document).on 'keydown', (evt)=>
      switch evt.keyCode
        when 32
          evt.preventDefault()
          @active_idea.handle_space_keypress()


jQuery(document).ready ->
  mindmap = new Mindmap jQuery('.mindmap')
  mindmap.init()

  mindmap.add mindmap.root_idea.insert_idea()
  mindmap.add mindmap.root_idea.insert_idea()
  mindmap.add mindmap.root_idea.insert_idea()
  mindmap.add mindmap.root_idea.insert_idea()
  
  mindmap.add mindmap.root_idea.children[0].insert_idea()
  mindmap.add mindmap.root_idea.children[0].insert_idea()

  mindmap.add mindmap.root_idea.children[2].insert_idea()
  mindmap.add mindmap.root_idea.children[2].insert_idea()
  mindmap.add mindmap.root_idea.children[2].insert_idea()

  mindmap.add mindmap.root_idea.children[2].children[2].insert_idea()
  mindmap.add mindmap.root_idea.children[2].children[2].insert_idea()


  mindmap.render()



  # 设置工具按钮操作事件
  # 导图居中显示
  mindmap.$el.delegate '.ops a.op.center', 'click', =>
    mindmap.center_to mindmap.root_idea, true

  mindmap.$el.delegate '.ops a.op.insert-idea', 'click', =>
    mindmap.insert_idea()


window.Mindmap = Mindmap
window.ANIMATE_DURATION = 200