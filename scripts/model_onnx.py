import os
import onnx
import onnx_tensorrt.backend as backend

class PatchInferencer:
    def __init__(self, model_onnx_file):
        model = onnx.load(model_onnx_file)
        self.engine = backend.prepare(model, enable_fp16=(os.getenv('ENABLE_FP16') == '1'))

    @property
    def compute_device(self):
        if os.getenv('ENABLE_FP16') == '1':
            return "tensorrt_fp16"
        else:
            return "tensorrt_fp32"


    def __call__(self, input_patch):
        output_patch = self.engine.run(input_patch)[0]
        return output_patch
