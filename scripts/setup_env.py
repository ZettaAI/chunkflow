import json
import os
import sys

with open(sys.argv[1]) as f:
    param = json.load(f)

target_mip = param["AFF_MIP"]
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
overlap = param.get("PATCH_OVERLAP", 0.5)

output_patch_overlap = [ int(x*overlap) + int(x*overlap)%2 for x in input_patch_size ]
output_chunk_margin = param.get("CHUNK_CROP_MARGIN", output_patch_overlap)

param["INPUT_PATCH_SIZE"] = " ".join(str(x) for x in input_patch_size[::-1])
param["OUTPUT_PATCH_SIZE"] = " ".join(str(x) for x in output_patch_size[::-1])
param["OUTPUT_PATCH_OVERLAP"] = " ".join(str(x) for x in output_patch_overlap[::-1])
param["OUTPUT_CROP_MARGIN"] = " ".join(str(x) for x in output_chunk_margin[::-1])

envs = ["VOL_START", "VOL_STOP", "AFF_PATH", "AFF_MIP", "IMAGE_RESOLUTION",
        "MAX_RAM", "MAX_MIP", "INPUT_PATCH_SIZE", "OUTPUT_PATCH_SIZE",
        "OUTPUT_PATCH_OVERLAP", "OUTPUT_CROP_MARGIN"]

for e in envs:
    print('export {}="{}"'.format(e, param[e]))
