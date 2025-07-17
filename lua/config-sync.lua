local config_sync = {}

local nvim_config_dir = vim.fn.stdpath("config")
local target_branch = "master"
local error_bar = {
	string.format("Configuration directory does not exist: %s", nvim_config_dir),
	string.format("Git branch is not specified: %s", target_branch),
	nil,
	nil,
	"Failed to fetch from remote repository",
	nil,
	"Git pull operation failed",
}

local exec_str = string.format(
	[[
nvim_config_dir="%s"; \
[ -d "$nvim_config_dir/.git" ] && [ -n "$nvim_config_dir" ] || exit 1; \
target_branch="%s"; \
[ -n "$target_branch" ] || exit 2; \
GIT="git -C $nvim_config_dir"; \
current_branch=$(${GIT} symbolic-ref --short HEAD 2>/dev/null || ${GIT} rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 3; \
[ "$current_branch" = "$target_branch" ] || exit 4; \
${GIT} fetch || exit 5; \
${GIT} rev-list HEAD..origin/"$target_branch" | grep -q . || exit 6; \
${GIT} pull || exit 7; \
exit 0
]],
	nvim_config_dir,
	target_branch
)

local function safe_notify(msg)
	vim.schedule(function()
		vim.notify(msg, vim.log.levels.ERROR)
	end)
end

local function check_update()
	---@diagnostic disable: missing-fields
	vim.loop.spawn("sh", {
		args = { "-c", exec_str },
	}, function(code)
		if error_bar[code] then
			safe_notify("Nvim update: " .. error_bar[code])
		end
	end)
end

function config_sync.setup(opts)
	if opts.target_branch then
		target_branch = opts.target_branch
	end
	vim.api.nvim_create_user_command("CheckUpdate", check_update, {})
end

return config_sync
