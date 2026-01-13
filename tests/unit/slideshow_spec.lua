-- Tests for lua/slideshow/ modules (T022, T023)

describe('slideshow', function()
  -- T022: Unit test for slideshow JSON parsing
  describe('parser', function()
    local parser

    before_each(function()
      package.loaded['slideshow.parser'] = nil
      parser = require('slideshow.parser')
    end)

    describe('parse_json()', function()
      it('should parse valid slideshow JSON', function()
        -- Arrange
        local json = '{"slides":[{"content":"Step 1","lines":[1,2,3]},{"content":"Step 2","lines":[5]}]}'

        -- Act
        local result, err = parser.parse_json(json)

        -- Assert
        assert.is_nil(err)
        assert.is_not_nil(result)
        assert.equals(2, #result.slides)
        assert.equals('Step 1', result.slides[1].content)
        assert.same({ 1, 2, 3 }, result.slides[1].lines)
        assert.equals('Step 2', result.slides[2].content)
        assert.same({ 5 }, result.slides[2].lines)
      end)

      it('should parse slide with empty lines array', function()
        -- Arrange
        local json = '{"slides":[{"content":"Intro","lines":[]}]}'

        -- Act
        local result, err = parser.parse_json(json)

        -- Assert
        assert.is_nil(err)
        assert.equals(1, #result.slides)
        assert.same({}, result.slides[1].lines)
      end)

      it('should return error for invalid JSON', function()
        -- Arrange
        local json = 'not valid json'

        -- Act
        local result, err = parser.parse_json(json)

        -- Assert
        assert.is_nil(result)
        assert.is_not_nil(err)
        assert.matches('parse', err:lower())
      end)

      it('should return error for missing slides array', function()
        -- Arrange
        local json = '{"content":"no slides array"}'

        -- Act
        local result, err = parser.parse_json(json)

        -- Assert
        assert.is_nil(result)
        assert.is_not_nil(err)
        assert.matches('slides', err:lower())
      end)

      it('should return error for empty slides array', function()
        -- Arrange
        local json = '{"slides":[]}'

        -- Act
        local result, err = parser.parse_json(json)

        -- Assert
        assert.is_nil(result)
        assert.is_not_nil(err)
      end)

      it('should return error for slide without content', function()
        -- Arrange
        local json = '{"slides":[{"lines":[1,2]}]}'

        -- Act
        local result, err = parser.parse_json(json)

        -- Assert
        assert.is_nil(result)
        assert.is_not_nil(err)
        assert.matches('content', err:lower())
      end)
    end)

    describe('parse_file()', function()
      it('should read and parse JSON file', function()
        -- This would require a test fixture file
        -- For now, test the file not found case
        local result, err = parser.parse_file('/nonexistent/file.json')

        assert.is_nil(result)
        assert.is_not_nil(err)
      end)
    end)
  end)

  -- T023: Unit test for navigation logic
  describe('navigation', function()
    local navigation

    before_each(function()
      package.loaded['slideshow.navigation'] = nil
      navigation = require('slideshow.navigation')
    end)

    describe('create()', function()
      it('should create navigator with slides', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = { 1 } },
          { content = 'Slide 2', lines = { 2 } },
          { content = 'Slide 3', lines = { 3 } },
        }

        -- Act
        local nav = navigation.create(slides)

        -- Assert
        assert.is_not_nil(nav)
        assert.equals(1, nav:current_index())
        assert.equals(3, nav:total())
      end)
    end)

    describe('next()', function()
      it('should advance to next slide', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
          { content = 'Slide 2', lines = {} },
        }
        local nav = navigation.create(slides)

        -- Act
        local slide = nav:next()

        -- Assert
        assert.equals(2, nav:current_index())
        assert.equals('Slide 2', slide.content)
      end)

      it('should return nil and show indicator at end', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
        }
        local nav = navigation.create(slides)

        -- Act
        local slide = nav:next()

        -- Assert
        assert.is_nil(slide)
        assert.equals(1, nav:current_index()) -- stays at last
        assert.is_true(nav:at_end())
      end)
    end)

    describe('prev()', function()
      it('should go to previous slide', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
          { content = 'Slide 2', lines = {} },
        }
        local nav = navigation.create(slides)
        nav:next() -- go to slide 2

        -- Act
        local slide = nav:prev()

        -- Assert
        assert.equals(1, nav:current_index())
        assert.equals('Slide 1', slide.content)
      end)

      it('should stay at first slide when already at beginning', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
          { content = 'Slide 2', lines = {} },
        }
        local nav = navigation.create(slides)

        -- Act
        local slide = nav:prev()

        -- Assert
        assert.is_nil(slide)
        assert.equals(1, nav:current_index())
      end)
    end)

    describe('goto_slide()', function()
      it('should jump to specific slide', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
          { content = 'Slide 2', lines = {} },
          { content = 'Slide 3', lines = {} },
        }
        local nav = navigation.create(slides)

        -- Act
        local slide = nav:goto_slide(3)

        -- Assert
        assert.equals(3, nav:current_index())
        assert.equals('Slide 3', slide.content)
      end)

      it('should clamp to valid range', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
          { content = 'Slide 2', lines = {} },
        }
        local nav = navigation.create(slides)

        -- Act
        local slide = nav:goto_slide(99)

        -- Assert
        assert.equals(2, nav:current_index())
      end)

      it('should clamp negative to first slide', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = {} },
          { content = 'Slide 2', lines = {} },
        }
        local nav = navigation.create(slides)
        nav:next() -- go to slide 2

        -- Act
        local slide = nav:goto_slide(-1)

        -- Assert
        assert.equals(1, nav:current_index())
      end)
    end)

    describe('current()', function()
      it('should return current slide', function()
        -- Arrange
        local slides = {
          { content = 'Slide 1', lines = { 5, 6 } },
        }
        local nav = navigation.create(slides)

        -- Act
        local slide = nav:current()

        -- Assert
        assert.equals('Slide 1', slide.content)
        assert.same({ 5, 6 }, slide.lines)
      end)
    end)

    describe('parse_command()', function()
      it('should parse next command', function()
        local cmd, arg = navigation.parse_command('next')
        assert.equals('next', cmd)
        assert.is_nil(arg)
      end)

      it('should parse prev command', function()
        local cmd, arg = navigation.parse_command('prev')
        assert.equals('prev', cmd)
        assert.is_nil(arg)
      end)

      it('should parse goto command with number', function()
        local cmd, arg = navigation.parse_command('goto 5')
        assert.equals('goto', cmd)
        assert.equals(5, arg)
      end)

      it('should parse quit command', function()
        local cmd, arg = navigation.parse_command('quit')
        assert.equals('quit', cmd)
      end)

      it('should return nil for unknown command', function()
        local cmd, arg = navigation.parse_command('unknown')
        assert.is_nil(cmd)
      end)

      it('should handle whitespace', function()
        local cmd, arg = navigation.parse_command('  next  ')
        assert.equals('next', cmd)
      end)

      it('should parse n as next shortcut', function()
        local cmd, arg = navigation.parse_command('n')
        assert.equals('next', cmd)
      end)

      it('should parse p as prev shortcut', function()
        local cmd, arg = navigation.parse_command('p')
        assert.equals('prev', cmd)
      end)

      it('should parse q as quit shortcut', function()
        local cmd, arg = navigation.parse_command('q')
        assert.equals('quit', cmd)
      end)

      it('should parse bare number as goto', function()
        local cmd, arg = navigation.parse_command('3')
        assert.equals('goto', cmd)
        assert.equals(3, arg)
      end)
    end)
  end)
end)
