--
-- Functions ------------------------------------------------------------------
--
local function create_md_link(filename)
    -- Create a markdown link from a filename
    -- Assumptions
    -- Filename follow the pattenrn: name_with_possible_underscores.md
    --
    local no_blanks = string.gsub(filename, "_", " ") -- Replace _ with " "
    local i = string.find(no_blanks, ".md")
    local title_part = string.sub(no_blanks, 1, i - 1)
    local title = string.upper(string.sub(title_part, 1, 1)) .. string.sub(title_part, 2, string.len(title_part))
    local md_link = '[' .. title .. '](' .. filename .. ")"
    -- print(md_link) -- DEBUG
    return md_link
end
--
-- Save Zettel to Kasten
local function zettel_title_to_filename(zettel_buf)
    -- Create a filename from an markdown text in a buffer
    -- Assumptions
    -- File starts with pandoc variables
    -- ---
    -- title: The title
    -- ...
    --
    local title_line_table = vim.api.nvim_buf_get_lines(zettel_buf, 1, 2, true)
    if string.find(title_line_table[1], "title:") == nil then
        print("Title not found. Probably not a Zettel!")
        return nil
    else
        local title_line = title_line_table[1]
        local i = string.find(title_line, ":")
        local title_part = string.gsub(
            string.lower(
                string.sub(title_line, i + 2, string.len(title_line))
            )
            , " ", "_")
        local date_part = os.date("%Y%m%d%H%M")
        local filename = date_part .. "_" .. title_part .. ".md"

        return filename
    end
end
--
--
-- Insert Markdown link of the in Telescope selected file,
-- useful for Zettelkasten
-- Requires Telescope!!
local t_action_state = require('telescope.actions.state')
local t_actions = require("telescope.actions")
function WriteFileNameToBuffer()
    local opts = {
        prompt_title = "~ Link to Zettel ~",
        shorten_path = false,
        -- cwd = "~/Nextcloud/Notes/", -- DEBUG
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
                -- Get actual selected Entry from Telescope
                local entry = t_action_state.get_selected_entry()

                -- print(vim.inspect(entry)) --DEBUG

                -- Close Telescope
                t_actions.close(prompt_bufnr)

                local md_link = create_md_link(entry.filename)
                -- Insert the link in current cursor position
                vim.cmd('normal i' .. md_link)

                -- Todo: Leave insert mode.
                -- No clue how to do it jet.
                -- Need to figure that out.
            end
            )
            return true
        end,
    }
    require('telescope.builtin').live_grep(opts)
end

vim.keymap.set('n', '<leader>ml', "<cmd>lua WriteFileNameToBuffer()<CR>", { desc = "ZK - Markdown link document" })
-- Go to Zettelkasten dir.
-- Must be set as environment variable KASTEN
vim.keymap.set('n', '<leader>zi', "<cmd>lua ZettelCd()<CR>",
    { desc = "ZK - cd to Zettelkasten directory" })

-------------------------------------------------------------------------------
--
-- Let's create a function to create a new Zettelkasten Zettel
-- Inspired by: https://www.youtube.com/watch?v=HlfjpstqXwE
--
-- -- Create a Zettel
vim.api.nvim_create_user_command("ZettelCreate", function()
    local title = vim.fn.input "Title: "
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(true, false)
    local now = os.date("%Y-%m-%d %H:%M")
    local text = { "---", "title: " .. title, "date: " .. now, "---" }
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, text)
    local zkpath = os.getenv("KASTEN")
    vim.cmd('cd ' .. zkpath)
    local filename = zettel_title_to_filename(buf)
    vim.cmd("save " .. filename)
    print(filename)
end, {})
--
vim.api.nvim_create_user_command("ZettelWrite", function()
    local buf = vim.api.nvim_get_current_buf()
    local filename = zettel_title_to_filename(buf)
    vim.cmd("save " .. filename)
    print(filename)
end, {})

vim.api.nvim_create_user_command("ZettelToDos", function()
    vim.cmd('vimgrep /-\\s\\[\\s]/g **/*.md')
    vim.cmd("copen")
end, {})

vim.api.nvim_create_user_command("ZettelCd", function()
    local zkpath = os.getenv("KASTEN")
    vim.cmd('cd ' .. zkpath)
    print("cd to " .. zkpath)
end, {})
