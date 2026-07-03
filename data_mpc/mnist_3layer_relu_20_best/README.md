# CROWN MPC Data Files

## Model Info
- **Model file**: `mnist_3layer_relu_20_best`
- **Output folder**: `mnist_3layer_relu_20_best`
- **Parsed parameters**:
  - model: mnist
  - numlayer: 3
  - hidden: 20
  - activation: relu
  - modeltype: best

## Network Structure
- Layers: 3
- Dimensions: 784 -> 20 -> 20 -> 10
- Activation: relu

## File Structure
```
mnist_3layer_relu_20_best/
├── weights/
│   └── weights.dat      # Model weights (W1,b1,W2,b2,...)
├── images/
│   ├── 0.bin            # Test images
│   ├── 1.bin
│   └── ...
├── labels.txt           # Image labels
├── config.txt           # Config info
└── README.md            # This file
```

## File Format

### weights/weights.dat
- Format: binary float32
- Storage order: W1, b1, W2, b2, W3, b3, ...
- W matrix shape: (output_dim, input_dim), row-major

### images/X.bin
- Format: binary float32
- Size: 784 values
- Value range: [-0.5, 0.5]

## C++ Usage Example

```bash
# Run the MPC program
./crown_mpc \
    --weights=mnist_3layer_relu_20_best/weights/weights.dat \
    --input=mnist_3layer_relu_20_best/images/0.bin \
    --eps=0.1 \
    --true_label=7 \
    --target_label=1
```

## C++ Config Code

```cpp
NetworkConfig config;
config.num_layers = 3;
config.layer_dims = {784, 20, 20, 10};
config.weights_file = "mnist_3layer_relu_20_best/weights/weights.dat";
config.input_file = "mnist_3layer_relu_20_best/images/0.bin";
config.eps = 0.1f;
```

## Verifying the Data

```python
import numpy as np

# Verify an image
img = np.fromfile('mnist_3layer_relu_20_best/images/0.bin', dtype=np.float32)
print(f"Image shape: {img.shape}, range: [{img.min():.3f}, {img.max():.3f}]")

# Verify the weights
weights = np.fromfile('mnist_3layer_relu_20_best/weights/weights.dat', dtype=np.float32)
print(f"Total weights: {weights.shape[0]}")
```

## Labels
The label file `labels.txt` contains the true label for each image.
