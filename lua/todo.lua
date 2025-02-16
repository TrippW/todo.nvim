local M = {}

-- @class todo.Task
-- @field title string: title of the task
-- @field created_at number: time the task was created
-- @field done boolean: whether the task is complete


-- @class todo.Project
-- @field id string: unique identifier for the project
-- @field title string: title of the project
-- @field path string: path to the project
-- @field tasks []todo.Task: list of tasks in the project

local root_path = vim.fn.stdpath("data")
if root_path == nil then
	root_path = vim.fn.getenv("HOME")
end
local file_path = vim.fs.joinpath(root_path, "todo.json")

-- @return string: load the todo file
local load_file = function()
  local file = io.open(file_path, "r")
  if file == nil then
    return vim.json.encode({ projects = {} })
  end
  local lines = file:read("*all")
  file:close()
  return lines
end

local save_file = function(data)
  local file = assert(io.open(file_path, "w"))
  file:write(vim.json.encode(data))
  file:close()
end

local render_project = function(project)
  local current_project = M.projects.projects[project]

  if current_project == nil then
    current_project = { tasks = {} }
  end

  local lines = {}
  for _, task in ipairs(current_project.tasks) do
    local line = "[" .. (task.done and "X" or " ") .. "] " .. task.title
    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_lines(M.display.tasks.buffer, 0, #lines, false, lines);
end

M.save_project = function(project, buf)
  local current_project = M.projects.projects[project]

  if current_project == nil then
    current_project = { tasks = {} }
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  current_project.tasks = {}
  for _, line in ipairs(lines) do
    if line:sub(1, 1) == "[" then
      local done = line:sub(2, 2) == "X"
      local title = line:sub(5)
      table.insert(current_project.tasks, { title = title, done = done })
    else
			line = vim.fn.trim(line)
			if line ~= "" then
				table.insert(current_project.tasks, { title = line, done = false })
			end
    end
  end

  M.projects.projects[project] = current_project
  save_file(M.projects)
end

M.toggle_task = function()
  M.save_project(M.cur_project, M.display.tasks.buffer)
  local current_project = M.projects.projects[M.cur_project]

  local task_i = vim.fn.getcurpos(M.display.tasks.window)[2]
  current_project.tasks[task_i].done = not current_project.tasks[task_i].done

  render_project(M.cur_project)

  M.save_project(M.cur_project, M.display.tasks.buffer)
end

local set_keymaps = function(buff, enable)
	if (buff and vim.fn.bufwinnr(buff) ~= -1) then
		if enable then
			vim.keymap.set("n", "<CR>", M.toggle_task, { noremap = true, buffer = buff })
		else
			vim.keymap.del("n", "<CR>", { buffer = buff })
		end
	end
end

M.display = {
	tasks = { buffer = -1, window = -1 },
	projects = { buffer = -1, window = -1 },
}

M.toggle = function()
	if M.display.tasks.window and vim.api.nvim_win_is_valid(M.display.tasks.window) then
		M.save_project(M.cur_project, M.display.tasks.buffer)
		set_keymaps(M.display.tasks.window, false)
		vim.api.nvim_win_close(M.display.tasks.window, true)
		vim.api.nvim_win_close(M.display.projects.window, true)
		M.display.tasks.window = nil
		M.display.tasks.buffer = nil
		M.display.projects.window = nil
		M.display.projects.buffer = nil
  else
		local width = vim.o.columns
		local height = vim.o.lines

    local buff = vim.api.nvim_create_buf(false, true);
    local win = vim.api.nvim_open_win(buff, true, {
      relative = "editor",
      row = 5,
      col = 4,
      height = height - 8 - 2,
      width = width - 8,
      border = "single",
      title = "Todo",
    });


		M.display.tasks.window = win
		M.display.tasks.buffer = buff

    M.display.projects.buffer = vim.api.nvim_create_buf(false, true);
    M.display.projects.window = vim.api.nvim_open_win(M.display.projects.buffer, false, {
      relative = "editor",
      row = 0,
      col = 4,
      height = 3,
      width = width - 8,
      border = "single",
			title = "Projects",
    });

		local projects = M.list_projects()

		vim.api.nvim_buf_set_lines(M.display.projects.buffer, 0, #projects, false, projects);

		local cur_index = 1
		-- Todo: swap with a binary search
		for i, project in ipairs(projects) do
			if project == M.cur_project then
				cur_index = i
				break
			end
		end

		vim.api.nvim_buf_add_highlight(M.display.projects.buffer, -1, "Visual", cur_index - 1, 0, width)
		vim.api.nvim_win_set_cursor(M.display.projects.window, { cur_index, 1 })

    set_keymaps(buff, true)
    render_project(M.cur_project)
  end
end

-- @return string[]: list of projects
M.list_projects = function()
	local projects = M.projects.projects
	local lines = {}
	for name, _ in pairs(projects) do
		table.insert(lines, name)
	end

	table.sort(lines)

	return lines
end



-- @param data string: data to parse
-- @return todo.ProjectList
local parse = function(data)
  return vim.json.decode(data)
end

M.cur_project = vim.fn.getcwd()
M.projects = parse(load_file())

return M
