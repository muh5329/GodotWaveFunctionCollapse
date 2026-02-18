# Wave Function Collapse in Godot

A Godot implementation of the Wave Function Collapse (WFC) algorithm for procedural generation.

## Overview

Wave Function Collapse is a procedural content generation technique that uses quantum mechanics principles to generate coherent, tileable patterns and environments. This example demonstrates WFC in Godot.

## Features

- Tile-based pattern generation
- Constraint propagation
- Entropy-based observation
- Configurable tile sets and rules

## Getting Started

1. Clone or download this project
2. Open in Godot 4.x
3. Run the main scene to generate patterns

## How It Works

1. **Initialize**: Start with all tiles in superposition
2. **Observe**: Select cell with lowest entropy
3. **Collapse**: Choose random valid tile
4. **Propagate**: Update neighboring constraints
5. **Repeat**: Continue until grid is fully collapsed

## Usage

```gdscript
var wfc = WaveFunction.new()
wfc.initialize(width, height, tiles)
wfc.collapse()
```

## Resources

- [Wave Function Collapse Algorithm](https://github.com/mxgmn/WaveFunctionCollapse)
- [Godot Documentation](https://docs.godotengine.org/)

## License

MIT