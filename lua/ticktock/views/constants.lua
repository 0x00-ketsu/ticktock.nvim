local M = {}

-- Ordered menu list
M.MENUS = {
  '📝 Todo', '✅ Completed', '🚮 Trash'
}

M.MENU_CHOICES = {
  ['📝 Todo'] = 'todo',
  ['✅ Completed'] = 'completed',
  ['🚮 Trash'] = 'trash'
}

M.HL_GROUP_CHOICES = {
  ['completed'] = 'TicktockCompleted',
  ['trash'] = 'TicktockDeleted'
}

return M
