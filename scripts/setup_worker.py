import json
import os
import sys

with open(sys.argv[1]) as f:
    param = json.load(f)

input_patch_size = param.get("INPUT_PATCH_SIZE",[256, 256, 20])
output_patch_size = param.get("OUTPUT_PATCH_SIZE", input_patch_size)
overlap = param.get("PATCH_OVERLAP", 0.5)

output_patch_overlap = [ int(x*overlap) + int(x*overlap)%2 for x in input_patch_size ]
output_chunk_margin = param.get("CHUNK_CROP_MARGIN", output_patch_overlap)

param["INPUT_PATCH_SIZE"] = " ".join(str(x) for x in input_patch_size[::-1])
param["OUTPUT_PATCH_SIZE"] = " ".join(str(x) for x in output_patch_size[::-1])
param["OUTPUT_PATCH_OVERLAP"] = " ".join(str(x) for x in output_patch_overlap[::-1])
param["OUTPUT_CROP_MARGIN"] = " ".join(str(x) for x in output_chunk_margin[::-1])
param["INFERENCE_OUTPUT_CHANNELS"] = 3 if "INFERENCE_OUTPUT_CHANNELS" not in param else param["INFERENCE_OUTPUT_CHANNELS"]
param["FRAMEWORK"] = "pytorch" if "FRAMEWORK" not in param else param["FRAMEWORK"]

envs = ["IMAGE_PATH", "IMAGE_MIP", "OUTPUT_PATH", "OUTPUT_MIP", "EXPAND_MARGIN_SIZE", "PATCH_NUM",
        "INFERENCE_OUTPUT_CHANNELS",
        "FRAMEWORK",
        "POSTPROC",
        "INPUT_PATCH_SIZE", "OUTPUT_PATCH_SIZE",
        "OUTPUT_PATCH_OVERLAP", "OUTPUT_CROP_MARGIN"]

for e in envs:
    if e in param:
        print('export {}="{}"'.format(e, param[e]))

if param.get("IMAGE_FILL_MISSING", False):
    print('export IMAGE_FILL_MISSING="--fill-missing"')

if "PYTORCH_MODEL_PATH" in param:
    print('export PYTORCH_MODEL_PKG="{}"'.format(os.path.join(param["PYTORCH_MODEL_PATH"])))

if "IMAGE_HISTOGRAM_PATH" in param:
    upper_threshold = param.get("CONTRAST_NORMALIZATION_UPPER_THRESHOLD", 0.01)
    lower_threshold = param.get("CONTRAST_NORMALIZATION_LOWER_THRESHOLD", 0.01)
    print('export CONSTRAST_NORMALIZATION="normalize-section-contrast -p {} -l {} -u {}"'.format(param["IMAGE_HISTOGRAM_PATH"], lower_threshold, upper_threshold))

if param.get("IMAGE_MASK_PATH", "N/A") != "N/A":
    operator = "mask --name=mask_image --volume-path={} --mip {}".format(param["IMAGE_MASK_PATH"], param["IMAGE_MASK_MIP"])
    if param.get("INVERT_IMAGE_MASK", True):
        operator += " --inverse"
    if param.get("IMAGE_MASK_FILL_MISSING", True):
        operator += " --fill-missing"
    operator += " --maskout --skip-to='save-aff'"
    print('export MASK_IMAGE="{}"'.format(operator))

if param.get("OUTPUT_MASK_PATH", "N/A") != "N/A":
    operator = "mask --name=mask_aff --volume-path={} --mip {}".format(param["OUTPUT_MASK_PATH"], param["OUTPUT_MASK_MIP"])
    if param.get("INVERT_OUTPUT_MASK", True):
        operator += " --inverse"
    if param.get("OUTPUT_MASK_FILL_MISSING", True):
        operator += " --fill-missing"
    operator += " --maskout"
    print('export MASK_OUTPUT="{}"'.format(operator))

if "MYELIN_MASK_THRESHOLD" in param:
    print('export EXTRA_INFERENCE_PARAM="--mask-myelin-threshold {}"'.format(float(param["MYELIN_MASK_THRESHOLD"])))
