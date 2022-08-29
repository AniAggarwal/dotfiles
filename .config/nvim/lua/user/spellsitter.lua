local status_ok, configs = pcall(require, "spellsitter")
if not status_ok then
	return
end


require('spellsitter').setup()
