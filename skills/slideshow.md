# Slideshow

Create and launch interactive slideshows to explain code with synchronized line highlighting.

Use this when the user asks you to explain code, debug issues, or walk through algorithms.

## How to Create and Launch

1. **Get the code buffer contents:**
   ```bash
   ./scripts/get_code_file.sh
   ```
   This returns the current contents of the code editor (including unsaved changes).

2. **Create and launch slideshow** by piping JSON to the launch script:
   ```bash
   cat << 'EOF' | ./scripts/launch_slideshow.sh --stdin
   {
     "slides": [
       {
         "content": "Explanation text for this slide",
         "lines": [1, 2, 3]
       }
     ]
   }
   EOF
   ```
   - `content`: Your explanation (newlines OK)
   - `lines`: Line numbers to highlight (1-indexed)

## Slide Guidelines

- Start with an overview slide
- One concept per slide
- Reference the highlighted lines in your explanation
- Keep explanations concise (tool pane is narrow)
- For debugging: walk through logic, point out the bug, suggest fix

## User Navigation

The user types in the tool pane:
- `n` or `next` - Next slide
- `p` or `prev` - Previous slide
- `q` or `quit` - Exit
- `3` or `goto 3` - Jump to slide 3

## Example Flow

User: "This loop isn't terminating, why?"

```bash
# 1. Get the code
./scripts/get_code_file.sh
# Returns the buffer contents directly

# 2. Analyze and launch slideshow (pipe JSON directly)
cat << 'EOF' | ./scripts/launch_slideshow.sh --stdin
{"slides":[{"content":"The issue is...","lines":[5,6,7]}]}
EOF
```
