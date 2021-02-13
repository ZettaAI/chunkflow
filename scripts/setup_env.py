import json
import os
import sys

with open(sys.argv[1]) as f:
    param = json.load(f)

target_mip = param["OUTPUT_MIP"]
mip0_factor = [2**target_mip, 2**target_mip, 1]
bbox = param["BBOX"]
image_resolution = param["IMAGE_RESOLUTION"]

vol_start = [int(bbox[i]*mip0_factor[i]) for i in range(3)]
vol_stop = [int(bbox[i+3]*mip0_factor[i]) for i in range(3)]
mip0_resolution = [image_resolution[i]/mip0_factor[i] for i in range(3)]

param["VOL_START"] = " ".join(str(x) for x in vol_start[::-1])
param["VOL_STOP"] = " ".join(str(x) for x in vol_stop[::-1])
param["IMAGE_RESOLUTION"] = " ".join(str(x) for x in mip0_resolution[::-1])


input_patch_size = param.get("INPUT_PATCH_SIZE",[256, 256, 20])
output_patch_size = param.get("OUTPUT_PATCH_SIZE", input_patch_size)

output_patch_overlap = param.get("OUTPUT_PATCH_OVERLAP", [ 128, 128, 10 ])
output_chunk_margin = param.get("CHUNK_CROP_MARGIN", [ 128, 128, 10 ])

param["INPUT_PATCH_SIZE"] = " ".join(str(x) for x in input_patch_size[::-1])
param["OUTPUT_PATCH_SIZE"] = " ".join(str(x) for x in output_patch_size[::-1])
param["OUTPUT_PATCH_OVERLAP"] = " ".join(str(x) for x in output_patch_overlap[::-1])
param["OUTPUT_CROP_MARGIN"] = " ".join(str(x) for x in output_chunk_margin[::-1])
param["OUTPUT_CHANNELS"] = param.get("OUTPUT_CHANNELS", 3)
param["OUTPUT_DTYPE"] = param.get("OUTPUT_DTYPE", "float32")

envs = ["VOL_START", "VOL_STOP", "OUTPUT_PATH", "OUTPUT_MIP", "IMAGE_RESOLUTION",
        "OUTPUT_CHANNELS", "OUTPUT_DTYPE",
        "MAX_RAM", "MAX_MIP", "INPUT_PATCH_SIZE", "OUTPUT_PATCH_SIZE",
        "OUTPUT_PATCH_OVERLAP", "OUTPUT_CROP_MARGIN"]

for e in envs:
    print('export {}="{}"'.format(e, param[e]))

if "PYTORCH_MODEL_PATH" in param:
    print('export PYTORCH_MODEL_PKG="{}"'.format(os.path.join(param["PYTORCH_MODEL_PATH"])))
