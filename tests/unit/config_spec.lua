-- Tests for lua/vim_leetcode_ai/config.lua

describe('config', function()
  local config

  before_each(function()
    package.loaded['vim_leetcode_ai.config'] = nil
    config = require('vim_leetcode_ai.config')
  end)

  describe('get()', function()
    it('should return default configuration', function()
      -- Act
      local cfg = config.get()

      -- Assert
      assert.equals('claude', cfg.ai_command)
      assert.equals('<leader>ai', cfg.keys.open)
      assert.equals('<leader>aq', cfg.keys.close)
      assert.equals(']s', cfg.keys.next_slide)
      assert.equals('[s', cfg.keys.prev_slide)
      assert.equals(0.5, cfg.layout.tool_width)
      assert.equals(0.3, cfg.layout.bottom_height)
    end)
  end)

  describe('setup()', function()
    it('should merge user options with defaults', function()
      -- Act
      config.setup({
        ai_command = 'aider',
        keys = {
          open = '<leader>ao',
        },
      })

      -- Assert
      local cfg = config.get()
      assert.equals('aider', cfg.ai_command)
      assert.equals('<leader>ao', cfg.keys.open)
      -- Other defaults should be preserved
      assert.equals('<leader>aq', cfg.keys.close)
      assert.equals(0.5, cfg.layout.tool_width)
    end)

    it('should allow deep nested option overrides', function()
      -- Act
      config.setup({
        layout = {
          bottom_height = 0.4,
        },
      })

      -- Assert
      local cfg = config.get()
      assert.equals(0.4, cfg.layout.bottom_height)
      -- Other layout options preserved
      assert.equals(0.5, cfg.layout.tool_width)
    end)

    it('should handle empty options', function()
      -- Act
      config.setup({})

      -- Assert: should have all defaults
      local cfg = config.get()
      assert.equals('claude', cfg.ai_command)
    end)

    it('should handle nil options', function()
      -- Act
      config.setup(nil)

      -- Assert: should have all defaults
      local cfg = config.get()
      assert.equals('claude', cfg.ai_command)
    end)
  end)
end)
