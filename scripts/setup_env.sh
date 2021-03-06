#!/bin/bash
python /workspace/chunkflow/scripts/setup_env.py /run/secrets/inference_param > /workspace/chunkflow/env.sh
source /workspace/chunkflow/scripts/init.sh
source /workspace/chunkflow/env.sh

if [ -n "$PYTORCH_MODEL_PKG" ]; then
    try gsutil cp ${PYTORCH_MODEL_PKG} ./pytorch-model.tgz
    try tar zxf pytorch-model.tgz -C /workspace/chunkflow
    export PYTHONPATH=/workspace/chunkflow/pytorch-model:$PYTHONPATH
fi

if [ -n "$ONNX_MODEL_PATH" ]; then
    try gsutil cp ${ONNX_MODEL_PATH} /workspace/chunkflow/model.chkpt
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
