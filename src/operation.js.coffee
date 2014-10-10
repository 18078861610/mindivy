# 所有操作类型：
# 1. 在指定节点上增加子节点
# 2. 删除节点（子树）
# 3. 折叠指定节点
# 4. 展开指定节点
# 5. 修改节点文字
# 6. 修改节点图片
# 7. 拖拽节点位置


# 增加子节点的操作实例
# 参数说明：
#   topic 在此节点上增加子节点
#   idx 子节点增加之后的下标
# 例如：
#   在叶子节点上增加子节点，idx = 0
#   在有两个子节点的节点上，在两个子节点中间增加节点，idx = 1
class Add
  constructor: (@topic, @idx)->

  # 执行操作动作
  excute: ->
    Operation.push_operation @
    if @idx is 0
      @topic.insert_topic {flash: true}
      @topic.mindmap.layout()

      @_new_topic = @topic.last_child()
      @_new_topic.fsm.select()

  # 重做操作动作
  forward: ->
    if @idx is 0
      @_new_topic.rendered = false
      @topic.insert_topic {flash: true, child_topic: @_new_topic}
      @topic.mindmap.layout()
      @_new_topic.fsm.select()


  # 撤销操作动作
  back: ->
    @_new_topic.delete_topic()
    @_new_topic.mindmap.layout()

push_operation: ->


Operation = {
  OPERATION_LIST: []
  max_undo_count: 0
  Add: Add

  push_operation: (operation)->
    arr = Operation.OPERATION_LIST[0...Operation.max_undo_count]
    arr.push operation
    Operation.OPERATION_LIST = arr

    Operation.max_undo_count = Operation.OPERATION_LIST.length
    jQuery(document).trigger 'mindmap:opertion-list-pushed'

  undo: ->
    operation = Operation.OPERATION_LIST[Operation.max_undo_count - 1]
    operation.back()
    Operation.max_undo_count--
    jQuery(document).trigger 'mindmap:opertion-undo'

  redo: ->
    operation = Operation.OPERATION_LIST[Operation.max_undo_count]
    operation.forward(false)
    Operation.max_undo_count++
    jQuery(document).trigger 'mindmap:opertion-redo'
}

window.Operation = Operation