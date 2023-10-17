#!/bin/bash

# Runs the "345M" parameter model

source_folder="/mnt/pvc/checkpoints"
target_folder="/mnt/checkpoints"
latest_checkpoint_file="${source_folder}/latest_checkpointed_iteration.txt"

if [ -f "$latest_checkpoint_file" ]; then
    latest_checkpoint=$(cat "$latest_checkpoint_file")
    formatted_checkpoint=$(printf "%07d" $latest_checkpoint)
    if [ -d "${source_folder}/iter_${formatted_checkpoint}" ]; then
        mkdir -p "${target_folder}/iter_${formatted_checkpoint}"
        cp -r "${source_folder}/iter_${formatted_checkpoint}/." "${target_folder}/iter_${formatted_checkpoint}/"
        cp "$latest_checkpoint_file" "${target_folder}/latest_checkpointed_iteration.txt"
        echo "Latest checkpoint copied to $target_folder"
    else
        echo "Latest checkpoint folder does not exist."
    fi
else
    echo "Latest checkpoint file not found or source folder does not exist."
fi

export CUDA_DEVICE_MAX_CONNECTIONS=1

if [ "$1" == "--save-to-pvc" ]; then
    CHECKPOINT_PATH=/mnt/pvc/checkpoints
else
    CHECKPOINT_PATH=/mnt/checkpoints
fi

VOCAB_FILE=/mnt/pvc/megatron-dev-dataset/gpt2-vocab.json
MERGE_FILE=/mnt/pvc/megatron-dev-dataset/gpt2-merges.txt
DATA_PATH=/mnt/pvc/megatron-dev-dataset/gpt2c4_text_document

DISTRIBUTED_ARGS="
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $WORLD_SIZE \
    --node_rank $RANK \
    --master_addr $MASTER_ADDR \
    --master_port $MASTER_PORT
"

GPT_ARGS="
    --tensor-model-parallel-size $TP_SIZE \
    --pipeline-model-parallel-size $PP_SIZE \
    --sequence-parallel \
    --num-layers $N_LAYERS \
    --hidden-size $D_MODEL \
    --num-attention-heads $N_HEADS \
    --seq-length 1024 \
    --max-position-embeddings 1024 \
    --micro-batch-size $M_BS \
    --global-batch-size $G_BS \
    --lr 0.00015 \
    --train-iters 500000 \
    --lr-decay-iters 320000 \
    --lr-decay-style cosine \
    --min-lr 1.0e-5 \
    --weight-decay 1e-2 \
    --lr-warmup-fraction .01 \
    --clip-grad 1.0 \
    --fp16
"

DATA_ARGS="
    --data-path $DATA_PATH \
    --vocab-file $VOCAB_FILE \
    --merge-file $MERGE_FILE \
    --data-impl mmap \
    --split 949,50,1
"

OUTPUT_ARGS="
    --log-interval 1 \
    --save-interval 1 \
    --eval-interval 1000 \
    --eval-iters 10
"

LOG_ARGS="
    --timing-log-level=1 \
    --timing-log-option=all
"

torchrun $DISTRIBUTED_ARGS pretrain_gpt.py \
    $GPT_ARGS \
    $DATA_ARGS \
    $OUTPUT_ARGS \
    $LOG_ARGS \
    --distributed-backend nccl \
    --use-tensorizer \
    --save $CHECKPOINT_PATH \
    --load $CHECKPOINT_PATH \
    --seed=42

