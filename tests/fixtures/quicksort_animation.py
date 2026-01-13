import time
import os


class QuicksortVisualizer:
    def __init__(self, array):
        self.array = array.copy()
        self.n = len(array)
        self.max_val = max(array)

        # ANSI color codes
        self.RESET = '\033[0m'
        self.RED = '\033[91m'      # Pivot
        self.GREEN = '\033[92m'    # Sorted
        self.YELLOW = '\033[93m'   # Comparing
        self.BLUE = '\033[94m'     # In partition
        self.GRAY = '\033[90m'     # Outside partition
        self.BOLD = '\033[1m'

    def clear_screen(self):
        """Clear the terminal screen."""
        os.system('clear' if os.name != 'nt' else 'cls')

    def draw_bar(self, value, color, width=3):
        """Draw a vertical bar for a value."""
        height = int((value / self.max_val) * 10)
        return color + '█' * width + self.RESET, height

    def visualize_state(self, pivot_idx=None, comparing_indices=None,
                       partition_bounds=None, sorted_indices=None, message=""):
        """Draw the current state of the array."""
        self.clear_screen()

        # Determine colors for each element
        colors = []
        for i in range(self.n):
            if sorted_indices and i in sorted_indices:
                colors.append(self.GREEN)
            elif pivot_idx is not None and i == pivot_idx:
                colors.append(self.RED)
            elif comparing_indices and i in comparing_indices:
                colors.append(self.YELLOW)
            elif partition_bounds and partition_bounds[0] <= i <= partition_bounds[1]:
                colors.append(self.BLUE)
            else:
                colors.append(self.GRAY)

        print(self.BOLD + "QUICKSORT VISUALIZATION" + self.RESET)
        print("=" * 60)
        print()

        # Draw bars from top to bottom
        for row in range(10, -1, -1):
            line = ""
            for i, val in enumerate(self.array):
                height = int((val / self.max_val) * 10)
                if height >= row:
                    line += colors[i] + '███' + self.RESET + ' '
                else:
                    line += '    '
            print(line)

        # Draw indices
        print('-' * (self.n * 4))
        index_line = ""
        for i in range(self.n):
            index_line += f'{i:^4}'
        print(index_line)

        # Draw values
        value_line = ""
        for val in self.array:
            value_line += f'{val:^4}'
        print(value_line)

        print()
        print("Legend: " + self.RED + "█ Pivot" + self.RESET +
              " | " + self.YELLOW + "█ Comparing" + self.RESET +
              " | " + self.BLUE + "█ Active Partition" + self.RESET +
              " | " + self.GREEN + "█ Sorted" + self.RESET +
              " | " + self.GRAY + "█ Inactive" + self.RESET)

        if message:
            print()
            print(self.BOLD + message + self.RESET)

        if pivot_idx is not None:
            print(f"Pivot: index {pivot_idx}, value {self.array[pivot_idx]}")
        if partition_bounds:
            print(f"Partition range: [{partition_bounds[0]}, {partition_bounds[1]}]")
        if sorted_indices:
            print(f"Sorted elements: {len(sorted_indices)}/{self.n}")

        time.sleep(0.8)

    def partition(self, low, high):
        """Partition the array and visualize each step."""
        pivot = self.array[high]
        self.visualize_state(pivot_idx=high, partition_bounds=(low, high),
                           message=f"Starting partition with pivot {pivot} at index {high}")

        i = low - 1

        for j in range(low, high):
            self.visualize_state(pivot_idx=high, comparing_indices=[j],
                               partition_bounds=(low, high),
                               message=f"Comparing {self.array[j]} with pivot {pivot}")

            if self.array[j] <= pivot:
                i += 1
                self.array[i], self.array[j] = self.array[j], self.array[i]
                self.visualize_state(pivot_idx=high, comparing_indices=[i, j],
                                   partition_bounds=(low, high),
                                   message=f"Swapped {self.array[j]} and {self.array[i]}")

        self.array[i + 1], self.array[high] = self.array[high], self.array[i + 1]
        self.visualize_state(pivot_idx=i + 1, partition_bounds=(low, high),
                           message=f"Pivot {pivot} placed at final position {i + 1}")

        return i + 1

    def quicksort(self, low, high, sorted_indices=None):
        """Perform quicksort and visualize each step."""
        if sorted_indices is None:
            sorted_indices = set()

        if low < high:
            pi = self.partition(low, high)
            sorted_indices.add(pi)
            self.visualize_state(sorted_indices=sorted_indices,
                               message=f"Element at index {pi} is now in final position")

            self.quicksort(low, pi - 1, sorted_indices)
            self.quicksort(pi + 1, high, sorted_indices)
        elif low == high:
            sorted_indices.add(low)
            self.visualize_state(sorted_indices=sorted_indices,
                               message=f"Single element at index {low} - already sorted")

    def sort(self):
        """Run the quicksort visualization."""
        self.visualize_state(message="Initial array - starting quicksort")
        time.sleep(1)

        self.quicksort(0, self.n - 1)

        final_sorted = set(range(self.n))
        self.visualize_state(sorted_indices=final_sorted, message="Sorting complete!")
        print("\nPress Enter to exit...")
        input()


# Run the visualization
if __name__ == '__main__':
    import random

    # Generate a random array
    random.seed(42)
    array = [random.randint(10, 99) for _ in range(12)]

    print("Initial array:", array)
    time.sleep(2)

    visualizer = QuicksortVisualizer(array)
    visualizer.sort()

    print("\nFinal sorted array:", visualizer.array)
