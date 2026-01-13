# Slideshow

Create and launch interactive slideshows to explain code with synchronized line highlighting.

Use this when the user asks you to explain code, debug issues, or walk through algorithms.

## How to Create and Launch

1. **Get the code buffer contents:**
   ```bash
   ./scripts/get_code_file.sh
   ```
   This returns the current contents of the code editor (including unsaved changes).

2. **Create slideshow JSON** and write to `/tmp/slideshow.json`:
   ```json
   {
     "slides": [
       {
         "content": "Explanation text for this slide",
         "lines": [1, 2, 3]
       }
     ]
   }
   ```
   - `content`: Your explanation (newlines OK)
   - `lines`: Line numbers to highlight (1-indexed)

3. **Launch the slideshow:**
   ```bash
   ./scripts/launch_slideshow.sh /tmp/slideshow.json
   ```

## Slide Guidelines

- Start with an overview slide
- One concept per slide
- Reference the highlighted lines in your explanation
- Keep explanations concise (tool pane is narrow)
- For debugging: walk through logic, point out the bug, suggest fix

## User Navigation

The user types in the tool pane:
- `next` / `prev` - Navigate slides
- `goto N` - Jump to slide N
- `quit` - Exit

## Example Flow

User: "This loop isn't terminating, why?"

```bash
# 1. Get the code
./scripts/get_code_file.sh
# Returns the buffer contents directly

# 2. Analyze and create slides, write to /tmp/slideshow.json

# 3. Launch
./scripts/launch_slideshow.sh /tmp/slideshow.json
```
