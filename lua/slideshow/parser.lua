-- slideshow parser module
-- Handles parsing of slideshow JSON data

local M = {}

--- Parse JSON string into slideshow data
---@param json_str string JSON string containing slideshow data
---@return table|nil slideshow Parsed slideshow data or nil on error
---@return string|nil error Error message if parsing failed
function M.parse_json(json_str)
  -- Try to decode the JSON
  local ok, data = pcall(vim.json.decode, json_str)
  if not ok then
    return nil, 'Failed to parse JSON: ' .. tostring(data)
  end

  -- Validate structure
  local err = M.validate(data)
  if err then
    return nil, err
  end

  return data, nil
end

--- Parse slideshow data from a file
---@param path string Path to JSON file
---@return table|nil slideshow Parsed slideshow data or nil on error
---@return string|nil error Error message if parsing failed
function M.parse_file(path)
  local file = io.open(path, 'r')
  if not file then
    return nil, 'Failed to open file: ' .. path
  end

  local content = file:read('*a')
  file:close()

  return M.parse_json(content)
end

--- Validate slideshow data structure
---@param data table Data to validate
---@return string|nil error Error message if validation failed
function M.validate(data)
  if type(data) ~= 'table' then
    return 'Invalid slideshow data: expected table'
  end

  if not data.slides then
    return 'Invalid slideshow data: missing slides array'
  end

  if type(data.slides) ~= 'table' then
    return 'Invalid slideshow data: slides must be an array'
  end

  if #data.slides == 0 then
    return 'Invalid slideshow data: slides array is empty'
  end

  -- Validate each slide
  for i, slide in ipairs(data.slides) do
    local slide_err = M.validate_slide(slide, i)
    if slide_err then
      return slide_err
    end
  end

  return nil
end

--- Validate a single slide
---@param slide table Slide to validate
---@param index number Slide index for error messages
---@return string|nil error Error message if validation failed
function M.validate_slide(slide, index)
  if type(slide) ~= 'table' then
    return string.format('Invalid slide %d: expected table', index)
  end

  if not slide.content then
    return string.format('Invalid slide %d: missing content field', index)
  end

  if type(slide.content) ~= 'string' then
    return string.format('Invalid slide %d: content must be a string', index)
  end

  if slide.content == '' then
    return string.format('Invalid slide %d: content cannot be empty', index)
  end

  -- lines is optional, but if present must be an array of numbers
  if slide.lines then
    if type(slide.lines) ~= 'table' then
      return string.format('Invalid slide %d: lines must be an array', index)
    end

    for j, line in ipairs(slide.lines) do
      if type(line) ~= 'number' or line < 1 or math.floor(line) ~= line then
        return string.format('Invalid slide %d: lines[%d] must be a positive integer', index, j)
      end
    end
  else
    -- Default to empty lines array
    slide.lines = {}
  end

  return nil
end

return M
