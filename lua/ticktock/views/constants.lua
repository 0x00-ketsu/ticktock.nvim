local M = {}

M.TODO_MENU = '📝 Todo'
M.COMPLETED_MENU = '✅ Completed'
M.TRASH_MENU = '🚮 Trash'

M.MENU_CHOICES = {['📝 Todo'] = 'todo', ['✅ Completed'] = 'completed', ['🚮 Trash'] = 'trash'}

M.HL_GROUP_CHOICES = {['completed'] = 'TicktockCompleted', ['trash'] = 'TicktockDeleted'}

return M
