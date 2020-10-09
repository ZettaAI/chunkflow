#!/bin/bash
python /root/workspace/chunkflow/scripts/setup_env.py /root/.cloudvolume/secrets/inference_param > /root/workspace/env.sh
source /root/workspace/env.sh

chunkflow setup-env -l ${AFF_PATH} \
    --volume-start ${VOL_START} --volume-stop ${VOL_STOP} \
    --max-ram-size ${MAX_RAM} \
    --input-patch-size ${INPUT_PATCH_SIZE} \
    --output-patch-size ${OUTPUT_PATCH_SIZE} --output-patch-overlap ${OUTPUT_PATCH_OVERLAP} --crop-chunk-margin ${OUTPUT_CROP_MARGIN} \
    --channel-num 3 \
    -m ${AFF_MIP} \
    --thumbnail --thumbnail-mip 5 \
    --voxel-size ${IMAGE_RESOLUTION} \
    --max-mip ${MAX_MIP} \
    -q amqp://172.31.31.249:5672
