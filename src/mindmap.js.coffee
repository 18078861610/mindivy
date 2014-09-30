class Mindmap
  constructor: (@$el)->
    @ideas = {}
    @bind_ops_events()
    @bind_ideas_events()


  init: ->
    @root_idea = new Idea('root', @)
    @add @root_idea


  render: ->
    for id, idea of @ideas
      @$el.append idea.render()
    @center_to @root_idea

  add: (idea)->
    @ideas[idea.id] = idea

  get: (idea_id)->
    return @ideas[idea_id]

  # 使得指定的节点在编辑器界面内居中显示
  center_to: (idea, is_animate)->
    editor_size = @get_editor_size()
    editor_width = editor_size.width
    editor_height = editor_size.height

    idea_size = idea.size()
    idea_width = idea_size.width
    idea_height = idea_size.height

    console.log editor_width, editor_height, idea_width, idea_height

    idea_left = (editor_width - idea_width) / 2
    idea_top  = (editor_height - idea_height) / 2

    idea.pos(idea_left, idea_top, is_animate)

  get_editor_size: ->
    width = @$el.width()
    height = @$el.height()

    return {
      width: width
      height: height
    }


  # 设置工具按钮操作事件
  bind_ops_events: ->
    # 导图居中显示
    @$el.delegate '.ops a.op.center', 'click', =>
      @center_to @root_idea, true


  # 设置导图节点事件
  bind_ideas_events: ->
    that = this
    # 单击选中节点
    @$el.delegate '.idea', 'click', (evt)->
      evt.stopPropagation()

      idea_id = jQuery(this).data('id')
      idea = that.get(idea_id)

      # 如果节点已经被选中，则开始编辑文字
      if idea.is_active()
        idea.edit_text()

      # 如果节点未被选中，选中节点
      else
        idea.select()

    # 节点文字编辑框的键盘响应
    @$el.delegate '.idea textarea.text-ipter', 'keydown', (evt)->
      idea_id = jQuery(this).closest('.idea').data('id')
      idea = that.get(idea_id)

      # 输入文字的同时动态调整 textarea 的大小
      setTimeout =>
        idea.adjust_text_ipter_size()

      switch evt.keyCode
        when 13
          if not evt.shiftKey
            # 按下回车时，结束编辑，保存当前文字，阻止原始的回车事件
            evt.preventDefault()
            idea.stop_edit_text()
          else 
            # 按下 shift + 回车时，换行
            # do nothing 执行 textarea 原始事件


    # 点击编辑器节点外区域时，如果节点在编辑状态，取消节点编辑
    @$el.delegate '.bottom-area', 'click', (evt)->
      if that.editing_idea
        that.editing_idea.stop_edit_text()

    
    # 全局按键事件
    jQuery(document).on 'keydown', (evt)=>
      switch evt.keyCode
        when 13
          # 如果当前有选中节点，按下回车时，开始编辑节点文字
          if @active_idea and @active_idea.is_active()
            evt.preventDefault()
            @active_idea.edit_text()


jQuery(document).ready ->
  mindmap = new Mindmap jQuery('.mindmap')
  mindmap.init()
  mindmap.render()

  root = mindmap.root_idea
  # console.log root, root.size().height, root.size().width

window.Mindmap = Mindmap
window.ANIMATE_DURATION = 200