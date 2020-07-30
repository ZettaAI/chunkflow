#!/bin/bash
python /root/workspace/chunkflow/scripts/setup_worker.py /run/variables/inference_param > /root/workspace/env.sh
source /root/workspace/env.sh

if [ -n "$PYTORCH_MODEL_PKG" ]; then
    gsutil cp ${PYTORCH_MODEL_PKG} ./pytorch-model.tgz
    tar zxvf pytorch-model.tgz -C /root/workspace/chunkflow
    export PYTHONPATH=/root/workspace/chunkflow/pytorch-model:$PYTHONPATH
fi

export PYTHONPATH=/root/workspace/chunkflow/DeepEM:$PYTHONPATH
export PYTHONPATH=/root/workspace/chunkflow/dataprovider3:$PYTHONPATH
export PYTHONPATH=/root/workspace/chunkflow/pytorch-emvision:$PYTHONPATH

echo "Start inference"
echo ${MASK_IMAGE}
echo ${MASK_AFF}

chunkflow --mip ${AFF_MIP} --verbose 0 \
    fetch-task-kombu -r 5 --queue-name=amqp://172.31.31.249:5672 \
    cutout --mip ${IMAGE_MIP} --volume-path="$IMAGE_PATH" --expand-margin-size ${EXPAND_MARGIN_SIZE} ${IMAGE_FILL_MISSING} \
    ${CONTRAST_NORMALIZATION} \
    ${MASK_IMAGE} \
    inference --name "aff-inference" \
        --convnet-model=/root/workspace/chunkflow/model.py \
        --convnet-weight-path=/root/workspace/chunkflow/model.chkpt \
        --dtype float32 \
        --num-output-channels 3 \
        --input-patch-size ${INPUT_PATCH_SIZE} \
        --output-patch-size ${OUTPUT_PATCH_SIZE} \
        --output-patch-overlap ${OUTPUT_PATCH_OVERLAP} \
        --output-crop-margin ${OUTPUT_CROP_MARGIN} \
        --framework='pytorch' \
        --batch-size 1 \
        --patch-num ${PATCH_NUM} \
    ${MASK_AFF} \
    save --name "save-aff" \
        --volume-path="$AFF_PATH" \
        --upload-log --create-thumbnail \
    delete-task-in-queue-kombu
