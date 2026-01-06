-- Import the wezterm module
local wezterm = require 'wezterm'
local appearance = require 'appearance'

local act = wezterm.action

-- Define variable for Hyperkey
local hyper_key = 'CTRL|ALT|CMD|SHIFT'

-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

config.color_scheme = 'Tokyo Night'

config.font = wezterm.font_with_fallback({
  "MesloLGS Nerd Font", -- Your primary font
  "JetBrains Mono",     -- Fallback font for better glyph support
  "Noto Color Emoji",   -- For emoji rendering
})

config.enable_scroll_bar = true
config.scrollback_lines = 10000 -- Increase scrollback buffer to 10,000 lines

-- Option key sends escape sequences (like iTerm2's "Esc+" mode)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Notification settings for Claude Code task completion alerts
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}
config.notification_handling = 'AlwaysShow'

-- And a font size that won't have you squinting
config.font_size = 13

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
-- Removes the title bar, leaving only the tab bar and window controls visible.
-- Keeps the ability to resize by dragging the window's edges.
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'

local function segments_for_right_status(window)
  -- Get the current workspace
  local workspace = window:active_workspace()

  -- Fetch battery information
  local battery_info = wezterm.battery_info()
  local battery = ""
  if #battery_info > 0 then
    local charge = battery_info[1].state_of_charge * 100
    battery = string.format('Battery: %.0f%%', charge)
  end

  -- Add segments: Only include the workspace if it's not "default"
  local segments = {}

  if workspace ~= "default" then
    table.insert(segments, workspace)
  end

  table.insert(segments, battery)
  table.insert(segments, wezterm.strftime('%a %b %-d %H:%M'))
  table.insert(segments, wezterm.hostname())

  return segments
end

wezterm.on('update-status', function(window, _)
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  local segments = segments_for_right_status(window)

  local color_scheme = window:effective_config().resolved_palette
  local bg = wezterm.color.parse(color_scheme.background)
  local fg = color_scheme.foreground

  local gradient_to, gradient_from = bg
  if appearance.is_dark() then
    gradient_from = gradient_to:lighten(0.2)
  else
    gradient_from = gradient_to:darken(0.2)
  end

  local gradient = wezterm.color.gradient(
    {
      orientation = 'Horizontal',
      colors = { gradient_from, gradient_to },
    },
    #segments
  )

  local elements = {}

  for i, seg in ipairs(segments) do
    local is_first = i == 1

    if is_first then
      table.insert(elements, { Background = { Color = 'none' } })
    end
    table.insert(elements, { Foreground = { Color = gradient[i] } })
    table.insert(elements, { Text = SOLID_LEFT_ARROW })

    table.insert(elements, { Foreground = { Color = fg } })
    table.insert(elements, { Background = { Color = gradient[i] } })
    table.insert(elements, { Text = ' ' .. seg .. ' ' })
  end

  window:set_right_status(wezterm.format(elements))
end)

config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.6,
}

-- Helper function to check if there is only one pane
wezterm.on('close-pane-or-exit', function(window, pane)
  -- Get the tab
  local tab = window:active_tab()

  -- Get the number of panes in the current tab
  local pane_count = #tab:panes()

  if pane_count == 1 then
    -- If only one pane, close the entire window
    window:perform_action(act.CloseCurrentTab { confirm = false }, pane)
  else
    -- Otherwise, close only the current pane
    window:perform_action(act.CloseCurrentPane { confirm = false }, pane)
  end
end)

local function move_pane(key, direction)
  return {
    key = key,
    mods = hyper_key,
    action = act.ActivatePaneDirection(direction),
  }
end

-- Helper function to define resizing keybindings
local function resize_pane(key, direction)
  return {
    key = key,
    mods = hyper_key .. '|SHIFT',
    action = act.AdjustPaneSize { direction, 1 },
  }
end

config.keys = {
  -- Shift+Enter and Option+Enter for newlines (useful for Claude Code)
  {
    key = 'Enter',
    mods = 'SHIFT',
    action = act.SendString '\n',
  },
  {
    key = 'Enter',
    mods = 'OPT',
    action = act.SendString '\x1b\x0d',  -- ESC + CR
  },

  -- Pane navigation with Hyperkey + Arrow
  move_pane('DownArrow', 'Down'),
  move_pane('UpArrow', 'Up'),
  move_pane('LeftArrow', 'Left'),
  move_pane('RightArrow', 'Right'),

  -- Pane resizing with Hyperkey + Shift + Arrow
  resize_pane('DownArrow', 'Down'),
  resize_pane('UpArrow', 'Up'),
  resize_pane('LeftArrow', 'Left'),
  resize_pane('RightArrow', 'Right'),

  -- Move cursor one word to the left with Option + LeftArrow
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = act.SendString '\x1bb', -- \x1b is ESC
  },
  -- Move cursor one word to the right with Option + RightArrow
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = act.SendString '\x1bf',
  },
  -- Move to the beginning of the line with Cmd + LeftArrow
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = act.SendString '\x01', -- Ctrl+A
  },
  -- Move to the end of the line with Cmd + RightArrow
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = act.SendString '\x05', -- Ctrl+E
  },
  -- Cmd + Backspace: Delete the entire line
  {
    key = 'Backspace',
    mods = 'CMD',
    action = act.SendString '\x15' -- \x15 is Ctrl+U
  },
  -- Cmd + Option + Backspace: Delete the last word
  {
    key = 'Backspace',
    mods = 'OPT',
    action = act.SendString '\x17' -- \x17 is Ctrl+W
  },
  -- Split vertically
  {
    key = 'v',
    mods = hyper_key,
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Split horizontally
  {
    key = 'h',
    mods = hyper_key,
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Cmd + ,: Open the config file in VSCode
  {
    key = ',',
    mods = 'CMD',
    action = act.SpawnCommandInNewWindow {
      args = { '/usr/local/bin/code', os.getenv('HOME') .. '/.config/wezterm/wezterm.lua' }
    },
  },
  -- Cmd + Enter: Toggle fullscreen and move to a new screen
  {
    key = 'Enter',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      -- First, toggle fullscreen
      window:perform_action(act.ToggleFullScreen, pane)
      -- Then, move the window to the next screen (if available)
      window:perform_action(act.MoveToNewTab { workspace = 'new_screen' }, pane)
    end),
  },
  -- Cmd + K: Clear the scrollback buffer and leave the viewport contents
  {
    key = 'K',
    mods = 'CMD',
    action = act.ClearScrollback 'ScrollbackOnly',
  },
  -- Clears the scrollback and viewport, then CTRL-L redraws the shell prompt
  {
    key = 'K',
    mods = 'CMD|SHIFT',
    action = act.Multiple {
      act.ClearScrollback 'ScrollbackAndViewport',
      act.SendKey { key = 'L', mods = 'CTRL' },
    },
  },
  -- Override the default keybinding for the command palette (command window)
  {
    key = 'P',
    mods = 'CMD|SHIFT',
    action = act.ActivateCommandPalette,
  },
  -- Bind cmd + w to close pane or close the application if it's the last one
  {
    key = 'w',
    mods = 'CMD',
    action = act.EmitEvent 'close-pane-or-exit'
  },

  -- Clear search and start fresh with CMD+F
  {
    key = 'f',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      -- First clear any existing search
      window:perform_action(
        act.Multiple {
          act.CopyMode 'ClearPattern',
          act.Search { CaseInSensitiveString = '' }
        },
        pane
      )
    end),
  },

  -- Quick clear search with Escape (when not in search mode)
  {
    key = 'Escape',
    mods = 'NONE',
    action = act.CopyMode 'ClearPattern',
  },

  -- Search for selected text
  {
    key = 'f',
    mods = 'CMD|SHIFT',
    action = act.Search 'CurrentSelectionOrEmptyString',
  },
}

config.key_tables = {
  search_mode = {
    -- Natural navigation
    { key = 'Enter', mods = 'NONE',  action = act.CopyMode 'NextMatch' },
    { key = 'Tab',   mods = 'NONE',  action = act.CopyMode 'NextMatch' },
    { key = 'Tab',   mods = 'SHIFT', action = act.CopyMode 'PriorMatch' },

    -- Quick clear with Escape
    {
      key = 'Escape',
      mods = 'NONE',
      action = act.Multiple {
        act.CopyMode 'ClearPattern',
        act.CopyMode 'Close',
      }
    },

    -- Standard arrow navigation
    { key = 'UpArrow',   mods = 'NONE', action = act.CopyMode 'PriorMatch' },
    { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },

    -- Quick copy with CMD+C
    {
      key = 'c',
      mods = 'CMD',
      action = act.Multiple {
        act({ CopyTo = 'Clipboard' }),
        act.CopyMode 'Close',
      }
    },

    -- Toggle case sensitivity with CMD+i
    { key = 'i',        mods = 'CMD',  action = act.CopyMode 'CycleMatchType' },

    -- Page navigation
    { key = 'PageUp',   mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
    { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
  },
}

return config
