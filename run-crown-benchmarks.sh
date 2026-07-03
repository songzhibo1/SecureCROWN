#!/bin/bash
set -e

# ==================== Network condition config ====================
# Options: LAN, WAN_40ms_600Mbps, WAN_60ms_600Mbps, WAN_40ms_370Mbps, WAN_60ms_370Mbps
# Can also be set via command line argument
NETWORK_CONDITION="${1:-LAN}"

# Network condition definitions (format: "delay bandwidth")
declare -A NETWORK_CONFIGS
NETWORK_CONFIGS["LAN"]="0.05ms 10Gbit"                    # Datacenter (RTT ~0.1ms)
# Sorted by bandwidth (high to low) and delay (low to high)
NETWORK_CONFIGS["WAN_40ms_600Mbps"]="20ms 600Mbit"   # (RTT 40ms)
NETWORK_CONFIGS["WAN_60ms_600Mbps"]="30ms 600Mbit"   # (RTT 60ms)
NETWORK_CONFIGS["WAN_40ms_370Mbps"]="20ms 370Mbit"   # Bandwidth 370Mbit
NETWORK_CONFIGS["WAN_60ms_370Mbps"]="30ms 370Mbit"   # Slowest
# Validate network condition
if [ -z "${NETWORK_CONFIGS[$NETWORK_CONDITION]}" ]; then
    echo "ERROR: Invalid NETWORK_CONDITION '$NETWORK_CONDITION'"
    echo "Available options: ${!NETWORK_CONFIGS[*]}"
    exit 1
fi

# Parse network parameters
NET_PARAMS=(${NETWORK_CONFIGS[$NETWORK_CONDITION]})
NET_DELAY="${NET_PARAMS[0]}"
NET_RATE="${NET_PARAMS[1]}"

# Set up network condition
setup_network() {
    echo "Setting up network condition: $NETWORK_CONDITION"
    echo "  Delay: $NET_DELAY (one-way), Rate: $NET_RATE"

    # Clear existing rules
    sudo tc qdisc del dev lo root 2>/dev/null || true

    # Apply new rules
    sudo tc qdisc add dev lo root netem delay $NET_DELAY rate $NET_RATE

    echo "Network condition applied successfully!"
    echo ""
}

# Clean up network condition
cleanup_network() {
    echo "Cleaning up network conditions..."
    sudo tc qdisc del dev lo root 2>/dev/null || true
}

# Set up network condition
setup_network

# Results directory prefix (includes network condition)
RESULTS_BASE_DIR="crown-results/${NETWORK_CONDITION}"

# ==================== Run configuration ====================
# Thread configuration list (0 = system default)
# Dealer preprocessing runs once; Server/Client run per thread count
THREADS_LIST=(4)

# Run mode: "both", "malicious", "semi-honest"
RUN_MODE="semi-honest"

# Create results directory
mkdir -p "$RESULTS_BASE_DIR"

# ==================== Network config ====================
IP_ADDRESS="127.0.0.1"

# ==================== Model configuration ====================
# Format: "num_layers hidden_dim input_dim output_dim"
declare -A MODEL_CONFIGS

# MNIST models
MODEL_CONFIGS["mnist_2layer_relu_20_best"]="2 20 784 10"
MODEL_CONFIGS["mnist_3layer_relu_20_best"]="3 20 784 10"

# MNIST models
MODEL_CONFIGS["vnncomp_mnist_3layer_relu_256_best"]="3 256 784 10"
MODEL_CONFIGS["vnncomp_mnist_5layer_relu_256_best"]="5 256 784 10"
MODEL_CONFIGS["vnncomp_mnist_7layer_relu_256_best"]="7 256 784 10"

# CIFAR models
MODEL_CONFIGS["cifar_6layer_relu_2048_best"]="6 2048 3072 10"
MODEL_CONFIGS["eran_cifar_5layer_relu_100_best"]="5 100 3072 10"
MODEL_CONFIGS["eran_cifar_7layer_relu_100_best"]="7 100 3072 10"
MODEL_CONFIGS["eran_cifar_10layer_relu_200_best"]="10 200 3072 10"

# ==================== Test sample configuration ====================
# Format: "num_layers hidden_dim input_dim output_dim"
# Source: samples with correct = True

declare -A IMAGE_CONFIGS


IMAGE_CONFIGS["mnist_3layer_relu_20_best"]="
0,7,6
1,2,4
2,1,5
3,0,3
4,4,0
5,1,6
6,4,0
9,9,6
10,0,4
11,6,7
12,9,6
13,0,4
14,1,0
15,5,4
16,9,1
17,7,6
19,4,0
20,9,6
21,6,7
22,6,3
23,5,2
24,4,0
25,0,3
26,7,6
27,4,0
28,0,4
29,1,0
30,3,6
31,1,0
32,3,4
33,4,7
34,7,6
35,2,4
36,7,6
37,1,0
38,2,4
39,1,2
40,1,0
41,7,6
42,4,6
43,2,9
44,3,0
45,5,7
46,1,0
47,2,9
48,4,0
49,4,6
50,6,7
51,3,4
52,5,2
53,5,4
54,6,3
55,0,4
56,4,0
57,1,5
58,9,6
59,5,6
60,7,6
64,7,6
65,4,0
66,6,4
67,4,6
68,3,4
69,0,4
70,7,6
71,0,4
72,2,4
73,9,6
74,1,0
75,7,6
76,3,4
77,2,4
78,9,6
79,7,6
80,7,6
81,6,3
82,2,4
83,7,6
84,8,0
85,4,0
86,7,6
87,3,0
88,6,3
89,1,0
90,3,4
91,6,7
92,9,0
93,3,6
94,1,0
95,4,3
96,1,0
97,7,6
98,6,7
99,9,6

"

IMAGE_CONFIGS["mnist_2layer_relu_20_best"]="
0,7,4
1,2,4
2,1,6
3,0,1
4,4,1
5,1,6
6,4,1
7,9,6
8,5,1
9,9,1
10,0,4
11,6,7
12,9,1
13,0,4
14,1,0
15,5,7
16,9,1
17,7,4
18,3,6
19,4,1
20,9,6
21,6,7
22,6,1
23,5,7
24,4,1
25,0,1
26,7,6
27,4,1
28,0,4
29,1,0
30,3,6
31,1,6
32,3,6
33,4,1
34,7,6
35,2,4
36,7,6
37,1,0
38,2,4
39,1,5
40,1,9
41,7,6
42,4,5
43,2,9
44,3,6
45,5,2
46,1,6
47,2,9
48,4,1
49,4,5
50,6,9
51,3,6
52,5,4
53,5,7
54,6,9
55,0,4
56,4,1
57,1,6
58,9,1
59,5,6
60,7,4
62,9,1
63,3,6
64,7,5
65,4,0
66,6,9
67,4,5
68,3,6
69,0,4
70,7,6
71,0,4
72,2,4
73,9,6
74,1,0
75,7,6
76,3,6
77,2,4
78,9,6
79,7,6
80,7,2
81,6,1
82,2,5
83,7,1
84,8,1
85,4,1
86,7,6
87,3,6
88,6,1
89,1,5
90,3,6
91,6,9
92,9,6
93,3,6
94,1,0
95,4,1
96,1,6
97,7,5
98,6,9
99,9,1

"



IMAGE_CONFIGS["vnncomp_mnist_3layer_relu_256_best"]="
0,7,3
1,2,1
"
#2,1,2
#3,0,7
#4,4,0
#5,1,2
#6,4,7
#7,9,7
#8,5,3
#9,9,7
#10,0,7
#11,6,5
#12,9,7
#13,0,5
#14,1,8
#15,5,4
#16,9,7
#17,7,2
#18,3,7
#19,4,0
#20,9,7
#21,6,5
#22,6,5
#23,5,7
#24,4,7
#25,0,7
#26,7,2
#27,4,0
#28,0,7
#29,1,4
#30,3,4
#31,1,4
#32,3,4
#33,4,7
#34,7,1
#35,2,7
#36,7,9
#37,1,4
#38,2,7
#39,1,8
#40,1,4
#41,7,2
#42,4,0
#43,2,0
#44,3,4
#45,5,4
#46,1,3
#47,2,7
#48,4,0
#49,4,0
#50,6,4
#51,3,4
#52,5,7
#53,5,4
#54,6,5
#55,0,7
#56,4,0
#57,1,3
#58,9,4
#59,5,7
#60,7,2
#61,8,1
#62,9,7
#63,3,4
#64,7,2
#65,4,7
#66,6,4
#67,4,0
#68,3,4
#69,0,5
#70,7,2
#71,0,5
#72,2,1
#73,9,4
#74,1,4
#75,7,2
#76,3,4
#77,2,1
#78,9,0
#79,7,9
#80,7,1
#81,6,5
#82,2,7
#83,7,1
#84,8,1
#85,4,0
#86,7,2
#87,3,4
#88,6,5
#89,1,2
#90,3,4
#91,6,5
#92,9,7
#93,3,7
#94,1,8
#95,4,7
#96,1,6
#97,7,2
#98,6,5
#99,9,7


IMAGE_CONFIGS["vnncomp_mnist_5layer_relu_256_best"]="
0,7,8
1,2,1
2,1,7
3,0,9
4,4,6
5,1,2
6,4,7
7,9,8
8,5,7
9,9,6
10,0,7
11,6,9
12,9,6
13,0,3
14,1,2
15,5,7
16,9,6
17,7,8
18,3,7
19,4,7
20,9,8
21,6,9
22,6,9
23,5,0
24,4,6
25,0,9
26,7,8
27,4,6
28,0,3
29,1,7
30,3,0
31,1,8
32,3,0
33,4,9
34,7,8
35,2,7
36,7,8
37,1,2
38,2,7
39,1,2
40,1,7
41,7,8
42,4,7
43,2,0
44,3,0
45,5,7
46,1,7
47,2,7
48,4,6
49,4,7
50,6,9
51,3,7
52,5,7
53,5,7
54,6,9
55,0,9
56,4,6
57,1,2
58,9,1
59,5,7
60,7,8
61,8,7
62,9,3
63,3,7
64,7,1
65,4,5
66,6,9
67,4,6
68,3,0
69,0,7
70,7,8
71,0,3
72,2,1
73,9,7
74,1,2
75,7,1
76,3,0
77,2,7
78,9,7
79,7,8
80,7,8
81,6,9
82,2,7
83,7,8
84,8,9
85,4,6
86,7,8
87,3,0
88,6,9
89,1,7
90,3,0
91,6,9
92,9,3
93,3,7
94,1,7
95,4,7
96,1,9
97,7,1
98,6,9
99,9,6
"

IMAGE_CONFIGS["vnncomp_mnist_7layer_relu_256_best"]="
    0,7,3
1,2,5
"
#2,1,5
#3,0,3
#4,4,2
#5,1,5
#6,4,3
#7,9,6
#8,5,2
#9,9,6
#10,0,3
#11,6,2
#12,9,2
#13,0,3
#14,1,5
#15,5,3
#16,9,2
#17,7,3
#18,3,9
#19,4,2
#20,9,2
#21,6,2
#22,6,2
#23,5,3
#24,4,3
#25,0,3
#26,7,3
#27,4,2
#28,0,3
#29,1,5
#30,3,2
#31,1,0
#32,3,2
#33,4,3
#34,7,3
#35,2,5
#36,7,3
#37,1,5
#38,2,5
#39,1,5
#40,1,0
#41,7,3
#42,4,2
#43,2,5
#44,3,2
#45,5,3
#46,1,5
#47,2,5
#48,4,2
#49,4,2
#50,6,2
#51,3,2
#52,5,3
#53,5,3
#54,6,2
#55,0,3
#56,4,2
#57,1,5
#58,9,6
#59,5,4
#60,7,5
#61,8,1
#62,9,2
#64,7,3
#65,4,3
#66,6,2
#67,4,2
#68,3,2
#69,0,3
#70,7,3
#71,0,3
#72,2,5
#73,9,6
#74,1,5
#75,7,5
#76,3,2
#77,2,5
#78,9,2
#79,7,3
#80,7,5
#81,6,2
#82,2,5
#83,7,5
#84,8,3
#85,4,2
#86,7,3
#87,3,2
#88,6,2
#89,1,5
#90,3,2
#91,6,2
#92,9,2
#93,3,2
#94,1,5
#95,4,2
#96,1,0
#97,7,3
#98,6,2
#99,9,6

IMAGE_CONFIGS["cifar_6layer_relu_2048_best"]="
    0,3,3
"

# eran_cifar_5layer_relu_100_best test samples (correct = True)
IMAGE_CONFIGS["eran_cifar_5layer_relu_100_best"]="
0,3,6
3,0,4
"
#6,1,4
#7,6,7
#9,1,6
#10,0,6
#11,9,5
#13,7,4
#14,9,8
#18,8,6
#19,6,1
#21,0,1
#23,9,3
#24,5,8
#25,2,8
#28,9,6
#29,6,8
#33,5,8
#34,9,8
#37,1,5
#38,9,5
#45,9,6
#47,9,8
#48,7,8
#49,6,8
#50,9,5
#54,8,6
#55,8,6
#56,7,1
#60,7,8
#61,3,1
#66,1,4
#67,2,9
#68,3,0
#72,8,5
#73,8,5
#76,9,8
#81,1,8
#83,7,1
#86,2,1
#88,8,6
#89,9,6
#92,8,6
#96,6,8
#99,7,8

IMAGE_CONFIGS["eran_cifar_7layer_relu_100_best"]="
    5,6,0
6,1,4
"
#7,6,5
#9,1,6
#10,0,6
#12,5,4
#13,7,6
#14,9,4
#18,8,3
#19,6,0
#20,7,6
#21,0,5
#23,9,4
#28,9,4
#29,6,8
#33,5,8
#34,9,4
#38,9,6
#45,9,4
#46,3,8
#47,9,6
#48,7,6
#50,9,4
#53,3,6
#55,8,3
#56,7,6
#60,7,3
#66,1,4
#68,3,9
#73,8,2
#74,0,3
#75,2,1
#76,9,4
#77,3,0
#78,3,7
#80,8,7
#81,1,4
#82,1,7
#86,2,7
#88,8,2
#89,9,4
#90,0,3
#92,8,7
#97,0,7
#98,0,1
#99,7,6

IMAGE_CONFIGS["eran_cifar_10layer_relu_200_best"]="
    1,8,4
6,1,4
"
#7,6,4
#8,3,8
#9,1,6
#10,0,4
#11,9,4
#13,7,6
#14,9,4
#18,8,4
#19,6,8
#23,9,4
#24,5,9
#26,4,0
#28,9,4
#29,6,4
#31,5,4
#32,4,5
#34,9,4
#37,1,2
#38,9,5
#39,5,0
#44,0,5
#45,9,5
#47,9,4
#48,7,4
#49,6,2
#50,9,4
#54,8,5
#55,8,5
#60,7,2
#65,2,4
#66,1,2
#67,2,4
#68,3,6
#72,8,7
#73,8,5
#74,0,5
#76,9,4
#78,3,4
#79,8,6
#81,1,6
#82,1,5
#86,2,5
#88,8,6
#89,9,4
#90,0,5
#92,8,4
#93,6,4
#97,0,5
#98,0,4
#99,7,6

MODELS_TO_TEST=(
#    "mnist_2layer_relu_20_best"
#    "mnist_3layer_relu_20_best"
#    "vnncomp_mnist_3layer_relu_256_best"
    "vnncomp_mnist_5layer_relu_256_best"
#    "vnncomp_mnist_7layer_relu_256_best"
#    "eran_cifar_5layer_relu_100_best"
#    "eran_cifar_7layer_relu_100_best"
#    "eran_cifar_10layer_relu_200_best"

)

#EPS_LIST=(0.005 0.01 0.025 0.05 0.08 0.1 0.2)
#EPS_LIST=(0.001 0.0015 0.0018 0.0022 0.0035)
#EPS_LIST=(0.001 0.0016 0.0019 0.0025)
#EPS_LIST=(0.0078)
#EPS_LIST=(0.015 0.045 0.1)
EPS_LIST=(0.015)
# ==================== Helper functions ====================
bytes_to_human() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    elif [ $bytes -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    else
        echo "$bytes bytes"
    fi
}

# Clean up residual processes
cleanup_processes() {
    echo "Cleaning up any remaining benchmark processes..."
    pkill -f "benchmark-crown" 2>/dev/null || true
    sleep 2
}

# Clean up on script exit (processes and network)
cleanup_all() {
    cleanup_processes
    cleanup_network
}
trap cleanup_all EXIT

# Determine which modes to run
MODES_TO_RUN=()
if [ "$RUN_MODE" = "both" ]; then
    MODES_TO_RUN=("malicious" "semi-honest")
elif [ "$RUN_MODE" = "malicious" ]; then
    MODES_TO_RUN=("malicious")
elif [ "$RUN_MODE" = "semi-honest" ]; then
    MODES_TO_RUN=("semi-honest")
else
    echo "ERROR: Invalid RUN_MODE '$RUN_MODE'. Use 'both', 'malicious', or 'semi-honest'."
    exit 1
fi

echo "========================================"
echo "Crown Benchmark Runner"
echo "========================================"
echo "Network:      $NETWORK_CONDITION ($NET_DELAY delay, $NET_RATE rate)"
echo "Results Dir:  $RESULTS_BASE_DIR"
echo "Threads List: ${THREADS_LIST[*]} (0 = system default)"
echo "Run Mode:     $RUN_MODE"
echo "Modes:        ${MODES_TO_RUN[*]}"
echo "========================================"
echo ""

# ==================== Main loop ====================
for model in "${MODELS_TO_TEST[@]}"; do
    config=(${MODEL_CONFIGS[$model]})
    NUM_LAYERS=${config[0]}
    HIDDEN_DIM=${config[1]}
    INPUT_DIM=${config[2]}
    OUTPUT_DIM=${config[3]}

    # Parse test sample configuration
    IMAGE_LIST=()
    while IFS= read -r line; do
        # Trim whitespace and skip empty lines
        line=$(echo "$line" | tr -d ' ')
        if [ -n "$line" ]; then
            IMAGE_LIST+=("$line")
        fi
    done <<< "${IMAGE_CONFIGS[$model]}"

    echo ""
    echo "########################################################"
    echo "# Model: $model"
    echo "# Layers: $NUM_LAYERS, Hidden: $HIDDEN_DIM"
    echo "# Input: $INPUT_DIM, Output: $OUTPUT_DIM"
    echo "# Test samples: ${#IMAGE_LIST[@]}"
    echo "#"
    echo "# Sample configs (id,true_class,target_class):"
    for sample in "${IMAGE_LIST[@]}"; do
        echo "#   $sample"
    done
    echo "########################################################"
    echo ""

    mkdir -p $RESULTS_BASE_DIR/$model

    for eps in "${EPS_LIST[@]}"; do
        echo "=========================================="
        echo "Testing EPS = $eps"
        echo "=========================================="

        mkdir -p $RESULTS_BASE_DIR/$model/eps_$eps

        # Iterate over all test samples
        for sample in "${IMAGE_LIST[@]}"; do
            # Parse id,true_class,target_class
            IFS=',' read -r IMAGE_ID TRUE_LABEL TARGET_LABEL <<< "$sample"

            echo ""
            echo "------------------------------------------"
            echo "Image $IMAGE_ID: true_class=$TRUE_LABEL, target_class=$TARGET_LABEL"
            echo "------------------------------------------"

            # Iterate over each mode
            for current_mode in "${MODES_TO_RUN[@]}"; do
                # Set mode flags and file suffixes
                if [ "$current_mode" = "semi-honest" ]; then
                    SH_FLAG="--semi-honest"
                    MODE_SUFFIX="_sh"
                    MODE_DISPLAY="Semi-Honest"
                else
                    SH_FLAG=""
                    MODE_SUFFIX="_m"
                    MODE_DISPLAY="Malicious"
                fi

                echo ""
                echo ">>> Running $MODE_DISPLAY mode..."

                # Build custom arguments (excluding thread settings)
                CUSTOM_ARGS="--model=$model --num_layers=$NUM_LAYERS --hidden_dim=$HIDDEN_DIM --input_dim=$INPUT_DIM --output_dim=$OUTPUT_DIM --eps=$eps --true_label=$TRUE_LABEL --target_label=$TARGET_LABEL --image_id=$IMAGE_ID $SH_FLAG"

                # ========== Dealer preprocessing (runs once per mode) ==========
                # Use a marker file to track which config generated the current dat files
                # Marker format: model_imageID_eps_mode
                DAT_MODE_MARKER=".dat_mode_marker"
                CURRENT_CONFIG="${model}_${IMAGE_ID}_${eps}${MODE_SUFFIX}"

                # Check if dealer result already exists for this mode
                DEALER_DONE=false

                # Check if dealer.txt exists (new or legacy format)
                DEALER_TXT_EXISTS=false
                for t in "${THREADS_LIST[@]}"; do
                    if [ -f "$RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}_t${t}_dealer.txt" ]; then
                        DEALER_TXT_EXISTS=true
                        break
                    fi
                done
                # Also check legacy dealer files without thread suffix
                if [ -f "$RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}_dealer.txt" ]; then
                    DEALER_TXT_EXISTS=true
                fi

                # Check if dat files exist and match current config
                DAT_FILES_VALID=false
                if [ -f "server.dat" ] && [ -f "client.dat" ]; then
                    if [ -f "$DAT_MODE_MARKER" ]; then
                        SAVED_CONFIG=$(cat "$DAT_MODE_MARKER")
                        if [ "$SAVED_CONFIG" = "$CURRENT_CONFIG" ]; then
                            DAT_FILES_VALID=true
                        else
                            echo "INFO: dat files are from different config ($SAVED_CONFIG), will regenerate for $CURRENT_CONFIG"
                        fi
                    else
                        echo "INFO: dat mode marker not found, will regenerate dat files"
                    fi
                fi

                # Skip preprocessing only if dealer.txt exists and dat files are valid
                if [ "$DEALER_TXT_EXISTS" = true ] && [ "$DAT_FILES_VALID" = true ]; then
                    DEALER_DONE=true
                fi

                if [ "$DEALER_DONE" = false ]; then
                    # Clean up previous processes
                    cleanup_processes

                    # Record dealer start time
                    DEALER_START=$(date +%s.%N)
                    echo "[$(date +'%H:%M:%S')] Starting DEALER preprocessing ($MODE_DISPLAY)..."

                    # DEALER (party 2) - preprocessing is thread-independent, runs once
                    ./build/benchmark-crown 2 $CUSTOM_ARGS &> $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}_dealer.txt
                    DEALER_EXIT_CODE=$?

                    DEALER_END=$(date +%s.%N)
                    DEALER_TIME=$(echo "$DEALER_END - $DEALER_START" | bc)

                    echo "[$(date +'%H:%M:%S')] DEALER preprocessing completed! (${DEALER_TIME}s)"

                    # Update marker only if dealer succeeded and dat files were generated
                    if [ $DEALER_EXIT_CODE -eq 0 ] && [ -f "server.dat" ] && [ -f "client.dat" ]; then
                        echo "$CURRENT_CONFIG" > "$DAT_MODE_MARKER"
                        echo "Updated dat marker: $CURRENT_CONFIG"
                    else
                        echo "WARNING: Dealer may have failed (exit code: $DEALER_EXIT_CODE), marker not updated"
                    fi

                    # Get file sizes
                    if [ -f "server.dat" ]; then
                        SERVER_SIZE=$(stat -c%s server.dat)
                        SERVER_HUMAN=$(bytes_to_human $SERVER_SIZE)
                    else
                        SERVER_SIZE=0
                        SERVER_HUMAN="NOT FOUND"
                    fi

                    if [ -f "client.dat" ]; then
                        CLIENT_SIZE=$(stat -c%s client.dat)
                        CLIENT_HUMAN=$(bytes_to_human $CLIENT_SIZE)
                    else
                        CLIENT_SIZE=0
                        CLIENT_HUMAN="NOT FOUND"
                    fi

                    TOTAL_SIZE=$((SERVER_SIZE + CLIENT_SIZE))
                    TOTAL_HUMAN=$(bytes_to_human $TOTAL_SIZE)

                    echo "Files: server.dat ($SERVER_HUMAN), client.dat ($CLIENT_HUMAN)"
                else
                    echo "[$(date +'%H:%M:%S')] DEALER preprocessing already done for $MODE_DISPLAY mode (eps=$eps), skipping..."
                    # Re-read file sizes for summary
                    if [ -f "server.dat" ]; then
                        SERVER_SIZE=$(stat -c%s server.dat)
                        SERVER_HUMAN=$(bytes_to_human $SERVER_SIZE)
                    else
                        SERVER_SIZE=0
                        SERVER_HUMAN="NOT FOUND"
                    fi
                    if [ -f "client.dat" ]; then
                        CLIENT_SIZE=$(stat -c%s client.dat)
                        CLIENT_HUMAN=$(bytes_to_human $CLIENT_SIZE)
                    else
                        CLIENT_SIZE=0
                        CLIENT_HUMAN="NOT FOUND"
                    fi
                    TOTAL_SIZE=$((SERVER_SIZE + CLIENT_SIZE))
                    TOTAL_HUMAN=$(bytes_to_human $TOTAL_SIZE)
                    DEALER_TIME="(skipped)"
                fi

                # ========== Execute Server/Client per thread count ==========
                for THREADS in "${THREADS_LIST[@]}"; do
                    THREAD_SUFFIX="_t${THREADS}"

                    echo ""
                    echo "    >>> Threads: $THREADS (t${THREADS})"

                    # Check if result already exists
                    if [ -f "$RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_summary.txt" ]; then
                        echo "    [SKIP] Results for EPS=$eps, Image=$IMAGE_ID, Mode=$MODE_DISPLAY, Threads=$THREADS already exist"
                        echo "    Quick preview:"
                        tail -5 "$RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_summary.txt" | sed 's/^/    /'
                        echo ""
                        continue
                    fi

                    # Wait for port release
                    echo "    [$(date +'%H:%M:%S')] Waiting for port to be available..."
                    sleep 3

                    # Launch SERVER and CLIENT
                    echo "    [$(date +'%H:%M:%S')] Starting SERVER and CLIENT ($MODE_DISPLAY, Threads=$THREADS)..."

                    # Start SERVER in background
                    if [ "$THREADS" = "0" ]; then
                        ./build/benchmark-crown 0 $IP_ADDRESS $CUSTOM_ARGS &> $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_server.txt &
                    else
                        OMP_NUM_THREADS=$THREADS ./build/benchmark-crown 0 $IP_ADDRESS $CUSTOM_ARGS &> $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_server.txt &
                    fi
                    SERVER_PID=$!

                    # Wait for SERVER to start listening
                    sleep 2

                    # Start CLIENT
                    if [ "$THREADS" = "0" ]; then
                        ./build/benchmark-crown 1 $IP_ADDRESS $CUSTOM_ARGS &> $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_client.txt
                    else
                        OMP_NUM_THREADS=$THREADS ./build/benchmark-crown 1 $IP_ADDRESS $CUSTOM_ARGS &> $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_client.txt
                    fi
                    CLIENT_EXIT_CODE=$?

                    # Wait for SERVER to finish
                    wait $SERVER_PID 2>/dev/null || true

                    echo "    [$(date +'%H:%M:%S')] Computation completed! ($MODE_DISPLAY, Threads=$THREADS)"

                    # Check exit codes
                    if [ $CLIENT_EXIT_CODE -ne 0 ]; then
                        echo "    WARNING: Client exited with code $CLIENT_EXIT_CODE"
                        echo "    Server output:"
                        cat $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_server.txt | sed 's/^/    /'
                        echo ""
                        echo "    Client output:"
                        cat $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_client.txt | sed 's/^/    /'
                    fi

                    # Create summary
                    {
                        echo "Results Summary"
                        echo "==============="
                        echo "Model: $model"
                        echo "Layers: $NUM_LAYERS, Hidden: $HIDDEN_DIM"
                        echo "Input: $INPUT_DIM, Output: $OUTPUT_DIM"
                        echo "EPS: $eps"
                        echo "Image ID: $IMAGE_ID"
                        echo "True Label: $TRUE_LABEL, Target Label: $TARGET_LABEL"
                        echo "Mode: $MODE_DISPLAY"
                        echo "Threads: $THREADS (0=system default)"
                        echo ""
                        echo "Preprocessing:"
                        echo "  Duration: $DEALER_TIME seconds"
                        echo "  server.dat: $SERVER_HUMAN"
                        echo "  client.dat: $CLIENT_HUMAN"
                        echo "  Total: $TOTAL_HUMAN"
                        echo ""
                        echo "Computation Results:"
                        # Extract and format results with unit conversion
                        while IFS= read -r line; do
                            if [[ "$line" =~ ^(End_to_end_time|crown_calculation|input):\ ([0-9]+)\ ms,\ ([0-9.]+)\ KB$ ]]; then
                                name="${BASH_REMATCH[1]}"
                                ms="${BASH_REMATCH[2]}"
                                kb="${BASH_REMATCH[3]}"
                                sec=$(awk "BEGIN {printf \"%.3f\", $ms/1000}")
                                mb=$(awk "BEGIN {printf \"%.3f\", $kb/1024}")
                                echo "$line  ($sec s, $mb MB)"
                            else
                                echo "$line"
                            fi
                        done < <(grep -E "(MPC LB:|MPC UB:|End_to_end_time|crown_calculation|input:)" $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_client.txt 2>/dev/null) || echo "  (No results found - check for errors)"
                    } > $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_summary.txt

                    echo ""
                    cat $RESULTS_BASE_DIR/$model/eps_$eps/image_${IMAGE_ID}${MODE_SUFFIX}${THREAD_SUFFIX}_summary.txt | sed 's/^/    /'
                    echo ""

                    # Wait for port release after each test
                    sleep 3
                done
            done
        done
    done

    # Create model summary (scan all existing results on disk)
    {
        echo "Model Summary: $model"
        echo "====================="
        echo "Layers: $NUM_LAYERS, Hidden: $HIDDEN_DIM"
        echo "Input: $INPUT_DIM, Output: $OUTPUT_DIM"
        echo "Threads List: ${THREADS_LIST[*]}"
        echo ""
        echo "Test samples in current config (id,true_class,target_class):"
        for sample in "${IMAGE_LIST[@]}"; do
            echo "  $sample"
        done
        echo ""
        echo "--- All Results Found in $RESULTS_BASE_DIR/$model ---"

        # Find all eps_ directories, sorted
        EXISTING_EPS_DIRS=$(find "$RESULTS_BASE_DIR/$model" -maxdepth 1 -type d -name "eps_*" | sort -V)

        if [ -z "$EXISTING_EPS_DIRS" ]; then
            echo "No results found on disk."
        else
            for eps_dir in $EXISTING_EPS_DIRS; do
                # Extract eps value from directory name
                eps_val=$(basename "$eps_dir" | sed 's/eps_//')

                echo "=== EPS = $eps_val ==="

                # Get all unique image IDs
                ALL_IMAGE_IDS=$(find "$eps_dir" -maxdepth 1 -name "image_*_client.txt" -o -name "image_*_m_*_client.txt" -o -name "image_*_sh_*_client.txt" 2>/dev/null | \
                    sed -E 's/.*image_([0-9]+)_.*/\1/' | sort -n | uniq)

                if [ -z "$ALL_IMAGE_IDS" ]; then
                    echo "  (No client output files found in this folder)"
                else
                    for img_id in $ALL_IMAGE_IDS; do
                        # Look up labels for this ID from config
                        config_str="${IMAGE_CONFIGS[$model]}"
                        matched_line=$(echo "$config_str" | grep -E "^\s*${img_id},")

                        if [ -n "$matched_line" ]; then
                            IFS=',' read -r _id _true _target <<< $(echo "$matched_line" | tr -d ' ')
                            echo "--- Image $_id (true=$_true, target=$_target) ---"
                        else
                            echo "--- Image $img_id (Labels not in current config) ---"
                        fi

                        # Find all client files for this image and categorize
                        # Malicious mode
                        MAL_FILES=$(find "$eps_dir" -maxdepth 1 -name "image_${img_id}_m_t*_client.txt" 2>/dev/null | sort -V)
                        if [ -n "$MAL_FILES" ]; then
                            echo "  [Malicious Mode]"
                            for mal_file in $MAL_FILES; do
                                # Extract thread count
                                thread_num=$(basename "$mal_file" | sed -E 's/.*_t([0-9]+)_client.txt/\1/')
                                echo "    Threads=$thread_num:"
                                while IFS= read -r line; do
                                    if [[ "$line" =~ ^(End_to_end_time|crown_calculation|input):\ ([0-9]+)\ ms,\ ([0-9.]+)\ KB$ ]]; then
                                        name="${BASH_REMATCH[1]}"
                                        ms="${BASH_REMATCH[2]}"
                                        kb="${BASH_REMATCH[3]}"
                                        sec=$(awk "BEGIN {printf \"%.3f\", $ms/1000}")
                                        mb=$(awk "BEGIN {printf \"%.3f\", $kb/1024}")
                                        echo "      $line  ($sec s, $mb MB)"
                                    else
                                        echo "      $line"
                                    fi
                                done < <(grep -E "(MPC LB:|MPC UB:|End_to_end_time|crown_calculation|input:)" "$mal_file" 2>/dev/null) || echo "      (No results content)"
                            done
                        fi

                        # Semi-honest mode
                        SH_FILES=$(find "$eps_dir" -maxdepth 1 -name "image_${img_id}_sh_t*_client.txt" 2>/dev/null | sort -V)
                        if [ -n "$SH_FILES" ]; then
                            echo "  [Semi-Honest Mode]"
                            for sh_file in $SH_FILES; do
                                # Extract thread count
                                thread_num=$(basename "$sh_file" | sed -E 's/.*_t([0-9]+)_client.txt/\1/')
                                echo "    Threads=$thread_num:"
                                while IFS= read -r line; do
                                    if [[ "$line" =~ ^(End_to_end_time|crown_calculation|input):\ ([0-9]+)\ ms,\ ([0-9.]+)\ KB$ ]]; then
                                        name="${BASH_REMATCH[1]}"
                                        ms="${BASH_REMATCH[2]}"
                                        kb="${BASH_REMATCH[3]}"
                                        sec=$(awk "BEGIN {printf \"%.3f\", $ms/1000}")
                                        mb=$(awk "BEGIN {printf \"%.3f\", $kb/1024}")
                                        echo "      $line  ($sec s, $mb MB)"
                                    else
                                        echo "      $line"
                                    fi
                                done < <(grep -E "(MPC LB:|MPC UB:|End_to_end_time|crown_calculation|input:)" "$sh_file" 2>/dev/null) || echo "      (No results content)"
                            done
                        fi

                        # Legacy format (no thread suffix)
                        OLD_MAL_FILE="$eps_dir/image_${img_id}_m_client.txt"
                        if [ -f "$OLD_MAL_FILE" ]; then
                            echo "  [Malicious Mode - Legacy (no thread info)]"
                            while IFS= read -r line; do
                                if [[ "$line" =~ ^(End_to_end_time|crown_calculation|input):\ ([0-9]+)\ ms,\ ([0-9.]+)\ KB$ ]]; then
                                    name="${BASH_REMATCH[1]}"
                                    ms="${BASH_REMATCH[2]}"
                                    kb="${BASH_REMATCH[3]}"
                                    sec=$(awk "BEGIN {printf \"%.3f\", $ms/1000}")
                                    mb=$(awk "BEGIN {printf \"%.3f\", $kb/1024}")
                                    echo "    $line  ($sec s, $mb MB)"
                                else
                                    echo "    $line"
                                fi
                            done < <(grep -E "(MPC LB:|MPC UB:|End_to_end_time|crown_calculation|input:)" "$OLD_MAL_FILE" 2>/dev/null) || echo "    (No results content)"
                        fi

                        OLD_SH_FILE="$eps_dir/image_${img_id}_sh_client.txt"
                        if [ -f "$OLD_SH_FILE" ]; then
                            echo "  [Semi-Honest Mode - Legacy (no thread info)]"
                            while IFS= read -r line; do
                                if [[ "$line" =~ ^(End_to_end_time|crown_calculation|input):\ ([0-9]+)\ ms,\ ([0-9.]+)\ KB$ ]]; then
                                    name="${BASH_REMATCH[1]}"
                                    ms="${BASH_REMATCH[2]}"
                                    kb="${BASH_REMATCH[3]}"
                                    sec=$(awk "BEGIN {printf \"%.3f\", $ms/1000}")
                                    mb=$(awk "BEGIN {printf \"%.3f\", $kb/1024}")
                                    echo "    $line  ($sec s, $mb MB)"
                                else
                                    echo "    $line"
                                fi
                            done < <(grep -E "(MPC LB:|MPC UB:|End_to_end_time|crown_calculation|input:)" "$OLD_SH_FILE" 2>/dev/null) || echo "    (No results content)"
                        fi

                        # Older legacy format (no _m or _sh suffix)
                        OLD_FILE="$eps_dir/image_${img_id}_client.txt"
                        if [ -f "$OLD_FILE" ]; then
                            echo "  [Legacy Format - Mode & Thread Unknown]"
                            while IFS= read -r line; do
                                if [[ "$line" =~ ^(End_to_end_time|crown_calculation|input):\ ([0-9]+)\ ms,\ ([0-9.]+)\ KB$ ]]; then
                                    name="${BASH_REMATCH[1]}"
                                    ms="${BASH_REMATCH[2]}"
                                    kb="${BASH_REMATCH[3]}"
                                    sec=$(awk "BEGIN {printf \"%.3f\", $ms/1000}")
                                    mb=$(awk "BEGIN {printf \"%.3f\", $kb/1024}")
                                    echo "    $line  ($sec s, $mb MB)"
                                else
                                    echo "    $line"
                                fi
                            done < <(grep -E "(MPC LB:|MPC UB:|End_to_end_time|crown_calculation|input:)" "$OLD_FILE" 2>/dev/null) || echo "    (No results content)"
                        fi

                        echo ""
                    done
                fi
            done
        fi
    } > $RESULTS_BASE_DIR/$model/model_summary.txt
done

echo ""
echo "=========================================================="
echo "All tests completed!"
echo "Network condition: $NETWORK_CONDITION"
echo "Results saved in: $RESULTS_BASE_DIR/"
echo "=========================================================="