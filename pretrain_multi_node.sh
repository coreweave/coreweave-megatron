#!/bin/bash

# Runs the "345M" parameter model

export CUDA_DEVICE_MAX_CONNECTIONS=1

CHECKPOINT_PATH=/mnt/pvc/checkpoints
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
    --num-layers $N_LAYERS \
    --hidden-size $D_MODEL \
    --num-attention-heads $N_HEADS \
    --seq-length 1024 \
    --max-position-embeddings 1024 \
    --micro-batch-size 8 \
    --global-batch-size 64 \
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
    --log-interval 100 \
    --save-interval 100 \
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
    --save $CHECKPOINT_PATH \
    --load $CHECKPOINT_PATH

