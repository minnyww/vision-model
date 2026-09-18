# Vision Models on Cloud Run (Ollama)

Ollama services on Cloud Run, project `vondercenter`, region `asia-southeast1`.
โมเดลถูก bake ลงใน container image ตั้งแต่ตอน build ดังนั้น instance ไม่ต้องโหลดโมเดลใหม่ทุกครั้งที่ cold start

## Services

| Service | Model | Specs | เหมาะกับ |
|---|---|---|---|
| `ollama-minicpm45` | minicpm-v4.5:8b (6.1GB) | 8 vCPU / 16Gi | **อ่านค่า/OCR จากรูปภาษาไทย — ตัวหลักที่ใช้ตอนนี้** |
| `ollama-glm-ocr` | glm-ocr (2.2GB) | 4 vCPU / 8Gi | OCR เอกสาร/label อังกฤษ เร็วและถูก |
| `ollama-minicpm` | minicpm-v4.6:1b (1.6GB) | 4 vCPU / 8Gi | อธิบายรูปทั่วไปสั้น ๆ (อ่าน label ไทยไม่แม่น) |

URL pattern: `https://<service>-39752824757.asia-southeast1.run.app`

## สลับ/เพิ่มโมเดล

```bash
gcloud builds submit . --config cloudbuild.yaml \
  --substitutions _MODEL=<ollama-model-tag>,_IMAGE=asia-southeast1-docker.pkg.dev/vondercenter/ollama/<image-name>

gcloud run deploy <service> --image asia-southeast1-docker.pkg.dev/vondercenter/ollama/<image-name> \
  --region asia-southeast1 --cpu 8 --memory 16Gi --timeout 600 --concurrency 2 --cpu-boost --allow-unauthenticated
```

(โมเดล >5GB ต้องใช้ memory 16Gi — ตัว 6.1GB จะ OOM ที่ 12Gi)

## สูตรสำเร็จ: ดึงค่าสถิติวิ่งจากรูป (JSON)

บทเรียนสำคัญ: ทุกโมเดลสับสนเลข `9:30 /กม.` (pace) กับ "เวลา" — ต้อง (1) ตั้งชื่อ field แบบเฉพาะเจาะจง (`total_duration`, `avg_pace_per_km` ไม่ใช่ `time`, `pace`) และ (2) เขียนกติกาแยกใน prompt

```bash
curl -s https://ollama-minicpm45-39752824757.asia-southeast1.run.app/api/chat -d @payload.json
# payload.json:
{
  "model": "minicpm-v4.5:8b",
  "messages": [{
    "role": "user",
    "content": "Read the workout stats in the image. IMPORTANT: avg_pace_per_km is the M:SS number that has /km (or /กม.) after it — that value is NOT the duration. total_duration is how long the whole run lasted (contains hours/minutes, e.g. 1 ชม. 34 น.). distance_km is the distance in km. calories is the kcal number.",
    "images": ["<base64 ของรูป>"]
  }],
  "stream": false,
  "think": false,
  "format": {
    "type": "object",
    "properties": {
      "distance_km": { "type": "number" },
      "total_duration": { "type": "string" },
      "avg_pace_per_km": { "type": "string" },
      "calories": { "type": "number" }
    },
    "required": ["distance_km", "total_duration", "avg_pace_per_km"]
  }
}
```

ผลทดสอบ (3 รอบติดกัน ตรงทุกค่า):
- รูป Strava ภาษาไทย: 9.96 km / 1 ชม. 34 น. / 9:30 /กม. / 563 kcal
- รูป Lemon8 ภาษาอังกฤษ: 5.23 km / 58m 16s / 11:08 /km
- latency ตอน warm ~11 วินาที (cold start ครั้งแรกนานกว่า ~1-2 นาที)

## หมายเหตุ

- `ollama pull` ของ Ollama รุ่นใหม่ต้องมี server รันอยู่ ใน Dockerfile จึง start `ollama serve` ชั่วคราวตอน build
- ทุก service เปิด `--allow-unauthenticated` เพื่อทดสอบ — ใช้งานจริงควรเพิ่ม auth
- ลบ service ที่ไม่ใช้: `gcloud run services delete <service> --region asia-southeast1`
# vision-model
