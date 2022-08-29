local status_ok, impatient = pcall(require, "leap")
if not status_ok then
  return
end

require('leap').set_default_keymaps()

