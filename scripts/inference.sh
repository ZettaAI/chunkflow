#!/bin/bash
python /workspace/chunkflow/scripts/setup_worker.py /run/secrets/inference_param > /workspace/chunkflow/env.sh
source /workspace/chunkflow/scripts/init.sh
source /workspace/chunkflow/env.sh

if [ -n "$PYTORCH_MODEL_PKG" ]; then
    try cloudfiles cp ${PYTORCH_MODEL_PKG} ./pytorch-model.tgz
    try tar zxvf pytorch-model.tgz -C /workspace/chunkflow
    export PYTHONPATH=/workspace/chunkflow/pytorch-model:$PYTHONPATH
fi

if [ -n "$ONNX_MODEL_PATH" ]; then
    try cloudfiles cp ${ONNX_MODEL_PATH} /workspace/chunkflow/model.chkpt
fi

export PYTHONPATH=/workspace/chunkflow/DeepEM:$PYTHONPATH
export PYTHONPATH=/workspace/chunkflow/dataprovider3:$PYTHONPATH
export PYTHONPATH=/workspace/chunkflow/pytorch-emvision:$PYTHONPATH

echo "Start inference"
echo ${MASK_IMAGE}
echo ${CROP_IMAGE}
echo ${SAVE_IMAGE}
echo ${MASK_OUTPUT}
echo ${CONTRAST_NORMALIZATION}
echo ${POST_PROCESS}

chunkflow --mip ${OUTPUT_MIP} --verbose 0 \
    fetch-task-kombu -r 10 --queue-name=amqp://172.31.31.249:5672 \
    cutout --mip ${IMAGE_MIP} --volume-path="$IMAGE_PATH" --expand-margin-size ${EXPAND_MARGIN_SIZE} ${IMAGE_FILL_MISSING} \
    ${CONTRAST_NORMALIZATION} \
    ${MASK_IMAGE} \
    ${CROP_IMAGE} \
    ${SAVE_IMAGE} \
    inference --name "aff-inference" \
        --convnet-model=${CONVNET_MODEL} \
        --convnet-weight-path=/workspace/chunkflow/model.chkpt \
        --dtype float32 \
        --num-output-channels ${INFERENCE_OUTPUT_CHANNELS} \
        --input-patch-size ${INPUT_PATCH_SIZE} \
        --output-patch-size ${OUTPUT_PATCH_SIZE} \
        --output-patch-overlap ${OUTPUT_PATCH_OVERLAP} \
        --output-crop-margin ${OUTPUT_CROP_MARGIN} \
        --framework=${INFERENCE_FRAMEWORK} \
        --batch-size 1 \
        --patch-num ${PATCH_NUM} \
        ${EXTRA_INFERENCE_PARAM} \
    ${POSTPROC} \
    ${MASK_OUTPUT} \
    save --name "save-aff" \
        --volume-path="$OUTPUT_PATH" \
        --upload-log --create-thumbnail \
    delete-task-in-queue-kombu
