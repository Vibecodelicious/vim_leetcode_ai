"""
LeetCode #20: Valid Parentheses

Given a string s containing just the characters '(', ')', '{', '}', '[' and ']',
determine if the input string is valid.

An input string is valid if:
1. Open brackets must be closed by the same type of brackets.
2. Open brackets must be closed in the correct order.
3. Every close bracket has a corresponding open bracket of the same type.

Example 1: Input: s = "()" Output: true
Example 2: Input: s = "()[]{}" Output: true
Example 3: Input: s = "(]" Output: false
"""


def isValid(s: str) -> bool:
    # Stack to keep track of opening brackets
    stack = []

    # Mapping of closing to opening brackets
    bracket_map = {
        ')': '(',
        '}': '{',
        ']': '['
    }

    # Iterate through each character
    for char in s:
        # If it's a closing bracket
        if char in bracket_map:
            # Pop from stack if not empty, else use dummy
            top = stack.pop() if stack else '#'

            # Check if it matches the correspondiMng opening bracket
            if bracket_map[char] != top:
                return False
        else:
            # It's an opening bracket, push to stack
            stack.append(char)

    # Valid if stack is empty (all brackets matched)
    return len(stack) == 0


# Test cases
if __name__ == "__main__":
    print(isValid("()"))        # True
    print(isValid("()[]{}"))    # True
    print(isValid("(]"))        # False
    print(isValid("([)]"))      # False
    print(isValid("{[]}"))      # True
