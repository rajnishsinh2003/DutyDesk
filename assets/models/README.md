# MobileFaceNet TFLite Model

Place the `mobilefacenet.tflite` model in this folder (`assets/models/mobilefacenet.tflite`).

### Model Specifications:
- **Architecture**: MobileFaceNet (or ArcFace Mobile)
- **Input Shape**: `[1, 112, 112, 3]` (RGB float32 normalized to `(pixel - 127.5) / 128.0`)
- **Output Shape**: `[1, 192]` (or `[1, 128]`, 192-dimensional L2-normalized float embedding)
- **File Name**: `mobilefacenet.tflite`

### Direct Download Options:
1. **GitHub Nicxlau Facenet TFLite**:
   - URL: `https://github.com/sirius-ai/MobileFaceNet_TF/raw/master/model/MobileFaceNet_9925_9680.tflite` or
   - `https://github.com/nicxlau/facenet_tflite/raw/master/assets/mobile_face_net.tflite`
2. **Rename the file to `mobilefacenet.tflite` and copy it to this directory**:
   `assets/models/mobilefacenet.tflite`
