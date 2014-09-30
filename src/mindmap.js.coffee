class Mindmap
  constructor: (@$el)->
    @ideas = {}
    @bind_ideas_events()


  init: ->
    @root_idea = new Idea('root', @)
    @add @root_idea
    return @

  render: ->
    for id, idea of @ideas
      @$el.append idea.render()
    @center_to @root_idea
    return @

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

    # console.log editor_width, editor_height, idea_width, idea_height

    idea_left = (editor_width - idea_width) / 2
    idea_top  = (editor_height - idea_height) / 2

    idea.pos(idea_left, idea_top, is_animate)

  # 在选择的节点上新增子节点
  insert_idea: ->
    if not @active_idea
      console.log '没有选中任何节点，无法增加子节点'
      return




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
  mindmap.init().render()


  # 设置工具按钮操作事件
  # 导图居中显示
  mindmap.$el.delegate '.ops a.op.center', 'click', =>
    mindmap.center_to mindmap.root_idea, true

  mindmap.$el.delegate '.ops a.op.insert-idea', 'click', =>
    mindmap.insert_idea()


window.Mindmap = Mindmap
window.ANIMATE_DURATION = 200