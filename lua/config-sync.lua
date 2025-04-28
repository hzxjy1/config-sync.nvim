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
current_branch=$(${GIT} branch --show-current 2>/dev/null) || exit 3; \
[ "$current_branch" = "$target_branch" ] || exit 4; \
${GIT} fetch || exit 5; \
${GIT} rev-list HEAD..origin/"$target_branch" | grep -q . || exit 6; \
${GIT} pull || exit 7; \
exit 0
]],
	nvim_config_dir,
	target_branch
)

local function check_update()
	---@diagnostic disable: missing-fields
	vim.loop.spawn("sh", {
		args = { "-c", exec_str },
	}, function(code)
		if error_bar[code] then
			vim.notify(error_bar[code])
		end
	end)
end

function config_sync.setup()
	vim.api.nvim_create_user_command("CheckUpdate", check_update, {})
end

return config_sync
