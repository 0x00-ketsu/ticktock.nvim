local logger = require('ticktock.contrib.log')

logger.outfile = string.format(
    '%s/%s.log', vim.api.nvim_call_function('stdpath', {'cache'}), 'ticktock'
)

return {debug = logger.debug, info = logger.info, warn = logger.warn, error = logger.error}
