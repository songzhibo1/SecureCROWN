# SecureCROWN: Privacy-Preserving Neural Network Robustness Verification

This repository contains the implementation of **SecureCROWN**, a secure two-party computation (2PC) framework for privacy-preserving neural network robustness verification, as described in our UAI 2026 paper:

> **Privacy-Preserving Robustness Verification for Neural Networks**  
> Nianyun Song, Xiaokun Luan, Yu Guo, Rongfang Bie, Meng Sun, Xiyue Zhang  
> *The 42nd Conference on Uncertainty in Artificial Intelligence (UAI), 2026*

SecureCROWN enables a model owner and a data owner to jointly compute certified robustness bounds without revealing their private data. The protocol is built on Function Secret Sharing (FSS) in the trusted dealer model with semi-honest security.

## Quick Start

```bash
# Build
cmake -DCMAKE_BUILD_TYPE=Release -S . -B build/
cmake --build build/ --config Release --target benchmark-crown -j

# Run a single verification (uses included example data)
# Step 1: Dealer generates preprocessing material
./build/benchmark-crown 2 --model=mnist_3layer_relu_20_best \
    --num_layers=3 --hidden_dim=20 --input_dim=784 --output_dim=10 \
    --eps=0.03 --true_label=7 --target_label=6 --image_id=0 --sh

# Step 2: Server (in background)
./build/benchmark-crown 0 127.0.0.1 --model=mnist_3layer_relu_20_best \
    --num_layers=3 --hidden_dim=20 --input_dim=784 --output_dim=10 \
    --eps=0.03 --true_label=7 --target_label=6 --image_id=0 --sh &

# Step 3: Client (outputs verification result)
./build/benchmark-crown 1 127.0.0.1 --model=mnist_3layer_relu_20_best \
    --num_layers=3 --hidden_dim=20 --input_dim=784 --output_dim=10 \
    --eps=0.03 --true_label=7 --target_label=6 --image_id=0 --sh
```

The `--sh` flag selects semi-honest mode. The client output contains `MPC LB` (certified lower bound): a positive value indicates the network is certifiably robust.

## Requirements

- CMake >= 3.16
- C++ compiler with C++20 support (GCC 10+ or Clang 12+)
- Eigen3: `sudo apt install libeigen3-dev` (Ubuntu/Debian) or `brew install eigen` (macOS)
- OpenMP (optional, for parallelization)
- `sudo` access (required for `tc` network simulation in benchmarks)

Alternatively, use Docker:

```bash
docker build --tag securecrown .
docker run --rm -it --privileged securecrown /bin/bash
```

The `--privileged` flag is needed for `tc` network simulation.

## Models and Data

### Benchmark Models

We evaluate on 8 fully-connected ReLU networks across two datasets:

| Name | Layers | Hidden Neurons | Dataset | Source |
|------|--------|---------------|---------|--------|
| 2×[20] | 2 | 20 | MNIST | [CROWN](https://github.com/huanzhang12/CROWN-Robustness-Certification) (Zhang et al., 2018) |
| 3×[20] | 3 | 20 | MNIST | [CROWN](https://github.com/huanzhang12/CROWN-Robustness-Certification) (Zhang et al., 2018) |
| 3×[256] | 3 | 256 | MNIST | [VNN-COMP](https://github.com/VNN-COMP/vnncomp2021_benchmarks) MNISTFC benchmark (Brix et al., 2023) |
| 5×[256] | 5 | 256 | MNIST | [VNN-COMP](https://github.com/VNN-COMP/vnncomp2021_benchmarks) MNISTFC benchmark (Brix et al., 2023) |
| 7×[256] | 7 | 256 | MNIST | [VNN-COMP](https://github.com/VNN-COMP/vnncomp2021_benchmarks) MNISTFC benchmark (Brix et al., 2023) |
| 5×[100] | 5 | 100 | CIFAR-10 | [ERAN](https://github.com/eth-sri/eran) (Singh et al., 2019) |
| 7×[100] | 7 | 100 | CIFAR-10 | [ERAN](https://github.com/eth-sri/eran) (Singh et al., 2019) |
| 10×[200] | 10 | 200 | CIFAR-10 | [ERAN](https://github.com/eth-sri/eran) (Singh et al., 2019) |

### Included Data

The `data_mpc/` directory includes two example models (`mnist_2layer_relu_20_best` and `mnist_3layer_relu_20_best`) for quick testing. Each model directory contains:

```
data_mpc/<model_name>/weights/weights.dat     # Model weights (binary, float32)
data_mpc/<model_name>/images/<id>.bin          # Test image (binary, float32)
```

### Preparing the Full Benchmark Data

To reproduce all results in the paper, download the remaining 6 pretrained models and export them to the same binary format:

- **MNIST 3×[256] to 7×[256]**: From the [VNN-COMP 2021 benchmarks](https://github.com/VNN-COMP/vnncomp2021_benchmarks) (MNISTFC benchmark).
- **CIFAR-10 5×[100] to 10×[200]**: From the [ERAN repository](https://github.com/eth-sri/eran).

### Plaintext Baseline

The plaintext CROWN verifier serves as the correctness oracle for validating that SecureCROWN produces numerically consistent verification outcomes. We use the implementation from the [CROWN repository](https://github.com/huanzhang12/CROWN-Robustness-Certification) (Apache 2.0 license):

```bash
git clone https://github.com/huanzhang12/CROWN-Robustness-Certification.git
# Follow their setup instructions, then run:
python main.py --model mnist --hidden 20 --numlayer 3 \
    --targettype random --norm i --numimage 100 --activation relu
```

## Running Benchmarks

### Full Benchmark Suite

Run all model configurations under a specified network condition (requires `sudo` for `tc`):

```bash
bash run-crown-benchmarks.sh LAN
```

### Network Conditions

Simulated via `tc` on the loopback interface:

| Condition | One-way Delay | Bandwidth |
|-----------|--------------|-----------|
| `LAN` | 0.05 ms | 10 Gbit/s |
| `WAN_40ms_370Mbps` | 20 ms | 370 Mbit/s |
| `WAN_40ms_600Mbps` | 20 ms | 600 Mbit/s |
| `WAN_60ms_370Mbps` | 30 ms | 370 Mbit/s |
| `WAN_60ms_600Mbps` | 30 ms | 600 Mbit/s |

### Two-Machine Setup

```bash
# On the dealer machine, generate preprocessing:
./build/benchmark-crown 2 <args>

# Copy server.dat to machine A, client.dat to machine B

# On machine A (server):
OMP_NUM_THREADS=4 ./build/benchmark-crown 0 <machine_B_IP> <args> --sh

# On machine B (client):
OMP_NUM_THREADS=4 ./build/benchmark-crown 1 <machine_A_IP> <args> --sh
```

## Output Format

Results are saved under `crown-results/<network_condition>/<model>/`:

```
image_<id>_sh_t<threads>_dealer.txt     # Dealer preprocessing log
image_<id>_sh_t<threads>_server.txt     # Server execution log
image_<id>_sh_t<threads>_client.txt     # Client log (contains verification bounds)
image_<id>_sh_t<threads>_summary.txt    # Parsed summary
```

The client output contains:
- `MPC LB` / `MPC UB`: Certified lower and upper bounds
- `End_to_end_time`: Total wall-clock time (ms) and communication (KB)
- `crown_calculation`: CROWN computation time (ms) and communication (KB)

## License

Our code is released under the [GNU General Public License v3.0](LICENSE).

## Third-Party Components

This implementation builds upon the [LLAMA](https://eprint.iacr.org/2022/793) library for FSS-based 2PC in the trusted dealer model. We extend LLAMA with the CROWN verification procedure. The core FSS primitives (DCF evaluation, fixed-point arithmetic, Newton–Raphson reciprocal) are from LLAMA and are unchanged.

| Component | License | Reference |
|-----------|---------|-----------|
| [LLAMA](https://eprint.iacr.org/2022/793) | MIT | Gupta et al., "LLAMA: A Low Latency Math Library for Secure Inference", PoPETs 2022 |
| [CROWN](https://github.com/huanzhang12/CROWN-Robustness-Certification) | Apache 2.0 | Zhang et al., "Efficient Neural Network Robustness Certification with General Activation Functions", NeurIPS 2018 |

## Citation

If you use this code in your research, please cite:

```bibtex
@inproceedings{song2026securecrown,
  title     = {Privacy-Preserving Robustness Verification for Neural Networks},
  author    = {Song, Nianyun and Luan, Xiaokun and Guo, Yu and 
               Bie, Rongfang and Sun, Meng and Zhang, Xiyue},
  booktitle = {The 42nd Conference on Uncertainty in Artificial 
               Intelligence ({UAI})},
  year      = {2026}
}
```
