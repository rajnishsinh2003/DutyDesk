# Biometric Face Verification System (DutyDesk)

## 1. System Architecture

DutyDesk has migrated from a legacy pixel-based comparison method (ZNCC, HOG, L1, scanline profiles) to an on-device deep facial recognition pipeline:

```
[ Camera Frame / Selfie ]
           │
           ▼
[ Google ML Kit Face Detection ]
  ├── 1 Face Validation
  ├── Real Head Euler Angles (Yaw ±10° Front, ~30° Profile)
  ├── Pitch / Roll constraint (±15°)
  ├── Eye-open Probability (Blink / Liveness detection)
  └── Image Quality Gate (Laplacian blur variance ≥ 45, Brightness 40-240)
           │
           ▼
[ 112x112 Square Face Crop & Alignment ]
  └── Margin: ~20% bounding-box expansion (hair, temples, chin)
  └── Normalized Tensor: ((pixel - 127.5) / 128.0)
           │
           ▼
[ MobileFaceNet TFLite Inference ]
  └── Generates 192-dimensional L2-normalized feature embedding
           │
           ▼
[ Cosine Similarity Comparison ]
  └── Compared against enrolled templates in Cloud Firestore (Front, Left, Right)
  └── Match Threshold: Cosine Similarity ≥ 0.50 (50.0%)
```

---

## 2. Why the Old Pixel-Based Matcher Failed

1. **White Oval Background Masking**: The old `_processImage()` method filled corners outside the face oval with pure RGB(255, 255, 255). This corrupted histogram equalization differently between stored photos and live frames.
2. **Aspect Ratio & Stretch Mismatch**: The live camera crop was 58% × 72% (aspect ~0.60), while the stored reference was 90% × 92% (aspect ~0.78). Stretching both to 128×128 distorted the same person's features differently.
3. **Lack of Invariant Embeddings**: Pixel matchers cannot handle natural changes in ambient room lighting, focal distance, or minor facial expressions.
4. **Heuristic Pose Angle**: Old left/right angle validation used horizontal skin-pixel mass distribution rather than actual 3D head rotation.

---

## 3. TFLite Model Setup

### Model File Location
The model must be placed at:
```
d:\E\DutyDesk\assets\models\mobilefacenet.tflite
```

### Model Specifications
- **Input Shape**: `[1, 112, 112, 3]` (RGB float32 normalized to `[-1.0, 1.0]`)
- **Output Shape**: `[1, 192]` (or `[1, 128]`, float32 embedding vector)
- **Model Architecture**: MobileFaceNet or ArcFace-Mobile

### Download Sources
You can download a pre-trained MobileFaceNet TFLite model from any of the following repositories:
1. **Sirius-AI MobileFaceNet**:
   `https://github.com/sirius-ai/MobileFaceNet_TF/raw/master/model/MobileFaceNet_9925_9680.tflite`
2. **Nicxlau FaceNet TFLite**:
   `https://github.com/nicxlau/facenet_tflite/raw/master/assets/mobile_face_net.tflite`

Download the file, rename it to `mobilefacenet.tflite`, and copy it to `assets/models/mobilefacenet.tflite`.

---

## 4. Configuration & Threshold Tuning (`lib/core/config/face_config.dart`)

All biometric constants are defined in `FaceConfig`:

| Constant | Default Value | Description & Tuning Advice |
|---|---|---|
| `maxFrontYaw` | `10.0°` | Maximum yaw allowed during front enrollment. Increase to `12.0°` if staff have trouble aligning. |
| `minLeftYaw` / `maxLeftYaw` | `20.0°` to `40.0°` | Left profile acceptable range. 30° captures distinctive nasal bridge and cheekbone contour. |
| `minRightYaw` / `maxRightYaw` | `-40.0°` to `-20.0°` | Right profile acceptable range. |
| `maxPitch` / `maxRoll` | `15.0°` | Prevents downward angles or tilted selfies that distort bone structure. |
| `minLaplacianVariance` | `45.0` | Sharpness threshold. Lower to `35.0` if low-end front cameras trigger blur errors in dim light. |
| `minFaceWidthRatio` | `0.25` | Face must occupy at least 25% of frame width to ensure adequate resolution. |
| `matchThreshold` | `0.50` | Cosine similarity threshold for verification match. Same person scores 0.60–0.92; different person scores 0.05–0.35. |
| `borderlineThreshold` | `0.40` | Borderline range `[0.40, 0.50)` triggers an automatic second stabilization frame. |
| `minPairSimilarityFrontSide` | `0.45` | Rejects enrollment if front and side profiles do not match (ensures same person). |
| `maxNearDuplicateSimilarity`| `0.98` | Rejects enrollment if user didn't actually turn their head between angles. |

---

## 5. Security & Privacy Architecture

### Supabase Key Deprecation & Rotation
1. The hardcoded Supabase anon key in `supabase_face_storage_service.dart` has been **removed from source control**.
2. **Action Required**: Log in to the [Supabase Dashboard](https://supabase.com/dashboard/project/mihrdepkliehtlekepdc/settings/api) and **rotate the anon/public API key**.
3. DutyDesk no longer stores raw face images in Supabase Storage. Biometrics are stored purely as encrypted mathematical vectors (192 doubles) in Cloud Firestore.

### India DPDP Act Compliance
- **Consent Banner**: Before enrollment, staff must accept a statutory consent screen outlining the purpose (exam anti-proxy), retention period, and storage policy.
- **Right to Erasure**: Staff can delete their face embeddings at any time using the "Delete Biometric Data" button in the enrollment dialog.
- **Audit Logging**: Clock-in attempts are logged to `face_verification_audit` with timestamp, score, and success status — without ever recording face images or embeddings.

---

## 6. Manual Testing Checklist

Run this comprehensive test battery before deploying to production:

- [ ] **Test 1: Same Person, Enrolled vs Live (Nominal Case)**
  - Clock in in good lighting. Verify match score is between 70% and 92% with green success banner.
- [ ] **Test 2: Same Person, Different Rooms & Lighting**
  - Test in fluorescent exam room light, warm light, and back-lit window. Ensure score stays ≥ 55%.
- [ ] **Test 3: Different Person (Anti-Proxy Test)**
  - Have a colleague attempt clock-in with your account. Ensure the match score is < 38% and the attempt is blocked.
- [ ] **Test 4: Distance Variance**
  - Stand 30 cm from phone vs 80 cm from phone. Bounding box auto-scaling must normalize and pass.
- [ ] **Test 5: Photo-of-a-Photo (Spoof Attempt)**
  - Present a printed photo or phone screen photo to the camera. Eye-open probability / liveness check should flag abnormal dynamics.
- [ ] **Test 6: Eyeglasses & Accessories**
  - Enroll without glasses, verify with glasses (and vice versa). MobileFaceNet embeddings are robust to thin-rim glasses.
- [ ] **Test 7: Low Light / Extreme Blur**
  - Cover lens slightly or verify in darkness. Should produce informative UI feedback ("Lighting is too dark" / "Image is blurry").
