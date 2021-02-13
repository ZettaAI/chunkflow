#!/bin/bash
python /root/workspace/chunkflow/scripts/setup_env.py /root/.cloudvolume/secrets/inference_param > /root/workspace/env.sh
source /root/workspace/chunkflow/scripts/init.sh
source /root/workspace/env.sh

if [ -n "$PYTORCH_MODEL_PKG" ]; then
    try gsutil cp ${PYTORCH_MODEL_PKG} ./pytorch-model.tgz
    try tar zxf pytorch-model.tgz -C /root/workspace/chunkflow
    export PYTHONPATH=/root/workspace/chunkflow/pytorch-model:$PYTHONPATH
fi

if [ -n "$ONNX_MODEL_PATH" ]; then
    try gsutil cp ${ONNX_MODEL_PATH} /root/workspace/chunkflow/model.chkpt
fi

chunkflow setup-env -l ${OUTPUT_PATH} \
    --volume-start ${VOL_START} --volume-stop ${VOL_STOP} \
    --max-ram-size ${MAX_RAM} \
    --input-patch-size ${INPUT_PATCH_SIZE} \
    --output-patch-size ${OUTPUT_PATCH_SIZE} --output-patch-overlap ${OUTPUT_PATCH_OVERLAP} --crop-chunk-margin ${OUTPUT_CROP_MARGIN} \
    --channel-num ${OUTPUT_CHANNELS} \
    -m ${OUTPUT_MIP} \
    -d ${OUTPUT_DTYPE} \
    --thumbnail --thumbnail-mip 5 \
    -e ${OUTPUT_ENCODING} \
    --voxel-size ${IMAGE_RESOLUTION} \
    --max-mip ${MAX_MIP} \
    -q amqp://172.31.31.249:5672
