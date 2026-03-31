#!/bin/bash
INPUT=$1
MAX_DISP=${2:-20}
BASENAME=$(basename $INPUT .mp4)

echo "==> 处理: $INPUT (max_disp=$MAX_DISP)"

mkdir -p ./outputs/disp${MAX_DISP}
mkdir -p ./results/disp${MAX_DISP}

SPLATTING=./outputs/disp${MAX_DISP}/${BASENAME}_splatting.mp4

if [ -f $SPLATTING ]; then
    echo "==> 第一步已完成，跳过"
else
    python depth_splatting_inference.py \
        --pre_trained_path ./weights/stable-video-diffusion-img2vid-xt-1-1 \
        --unet_path ./weights/DepthCrafter \
        --input_video_path $INPUT \
        --output_video_path $SPLATTING \
        --max_disp $MAX_DISP

    if [ $? -ne 0 ]; then
        echo "==> 第一步失败: $INPUT"
        exit 1
    fi
fi

echo "==> 开始第二步"

for attempt in 1 2 3; do
    echo "==> 第二步尝试 $attempt/3"
    sleep 10
    python inpainting_inference.py \
        --pre_trained_path ./weights/stable-video-diffusion-img2vid-xt-1-1 \
        --unet_path ./weights/StereoCrafter \
        --input_video_path $SPLATTING \
        --save_dir ./results/disp${MAX_DISP}/${BASENAME}_final

    if [ $? -eq 0 ]; then
        echo "==> 完成: $BASENAME"
        exit 0
    fi
    echo "==> 第二步失败，重试..."
done

echo "==> 第二步最终失败: $INPUT"
exit 1
