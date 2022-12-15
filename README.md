# Cereal Demo

## Prologue
Never have interfaced or leveraged AVFoundation, TensorflowLite, TensorflowLiteTaskVision, or Vision librarires


## Completed
- Leveraged SwiftUI & MVVM methodology
- Integrated Cocoapod's from scratch
- Leveraged AVFoundation to create a Camera that obtain `pixelBuffer` to do on-device processing
- Leveraged TensorFlowLiteTaskVision to use `cereal_model.tflite` to do product classification
- Custom App icon

## In-progress / Unfinished
- Attempted Object Detection with `ObjectDetector` & `ssd_mobilenet_v1.tflite` but obviously model not trained for the right object detection
- Created `best-int8.tflite` using YOLOv5-OBB by running this model with manually labeled data to improve both product classfication confidence and bound-box detection

## Experiemented
- Used Roboflow to create ML model ("https://detect.roboflow.com/cereal-0d7rp/1?api_key=<API_KEY>") but Cocoapod `Roboflow`'s `RoboflowMobile(apikey: )` was not working

## Dev Time
- 10hrs for research, development, and testing

## Demo
- [Recording](https://drive.google.com/file/d/1_vkHvpI8h8pgDXUsx4N3nCWNTARRhVcG/view?usp=sharing)


## Resources
- [TensorFlowLite Image Classification Example](https://github.com/tensorflow/examples/tree/master/lite/examples/image_classification/ios)
- [TensorFlowLite Object Detection Example](https://github.com/tensorflow/examples/tree/master/lite/examples/object_detection/ios)
- [YOLOv5-OBB](https://www.youtube.com/watch?t=36&v=iRkCNo9-slY&embeds_euri=https%3A%2F%2Fblog.roboflow.com%2F&feature=emb_imp_woyt)
- [YOLOv5 Custom Dataset](https://www.youtube.com/watch?v=MdF6x6ZmLAY&t=1180s)
- [AV Foundation](https://developer.apple.com/av-foundation/)
