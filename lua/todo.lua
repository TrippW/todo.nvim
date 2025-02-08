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

local file_path = os.getenv("HOME") .. "/.local/share/nvim/todo.json"


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

  vim.api.nvim_buf_set_lines(M.cur_buf, 0, #lines, false, lines);
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
      table.insert(current_project.tasks, { title = line, done = false })
    end
  end

  M.projects.projects[project] = current_project
  save_file(M.projects)
end

M.toggle_task = function()
  M.save_project(M.cur_project, M.cur_buf)
  local current_project = M.projects.projects[M.cur_project]

  local task_i = vim.fn.getcurpos(M.cur_win)[2]
  print(task_i)
  current_project.tasks[task_i].done = not current_project.tasks[task_i].done

  render_project(M.cur_project)

  M.save_project(M.cur_project, M.cur_buf)
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

M.toggle = function()
	if M.cur_buf then
		if vim.fn.bufwinnr(M.cur_buf) ~= -1 then
			M.save_project(M.cur_project, M.cur_buf)
			set_keymaps(M.cur_buf, false)
			vim.api.nvim_win_close(M.cur_win, true)
		end
		M.cur_win = nil
		M.cur_buf = nil
  else
    local buff = vim.api.nvim_create_buf(false, true);
    local height = vim.fn.winheight(0);
    local width = vim.fn.winwidth(0);
    local win = vim.api.nvim_open_win(buff, true, {
      relative = "win",
      row = 2,
      col = 4,
      height = height - 4,
      width = width - 8,
      border = "single",
      title = "Todo",
    });

    M.cur_win = win;
    M.cur_buf = buff;

    set_keymaps(buff, true)
    render_project(M.cur_project)
  end
end

-- @param data string: data to parse
-- @return todo.ProjectList
local parse = function(data)
  return vim.json.decode(data)
end

M.cur_project = vim.fn.getcwd()
M.projects = parse(load_file())

return M
