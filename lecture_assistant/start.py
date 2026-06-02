import json

print(" Lecture Assistant Setup")
print("=" * 40)
print("حطي الـ base URL بدون /transcribe أو /ocr:")
print("مثال: https://writing-shindig-tubular.ngrok-free.dev")
print()

whisper_url = input("رابط Whisper (base URL): ").strip().rstrip("/")
ocr_url     = input("رابط OCR (base URL): ").strip().rstrip("/")
summary_url = input("رابط Summary (base URL): ").strip().rstrip("/")
quiz_url    = input("رابط Quiz (base URL): ").strip().rstrip("/")

config = {
    "whisper_url": whisper_url,
    "ocr_url":     ocr_url,
    "summary_url": summary_url,
    "quiz_url":    quiz_url
}

with open("config.json", "w") as f:
    json.dump(config, f, indent=2)

print(f"\n تم الحفظ!")
print(f"Whisper : {whisper_url}/transcribe-async")
print(f"OCR     : {ocr_url}/ocr-async")
print(f"Summary : {summary_url}/summarize-all-async")
print(f"Quiz    : {quiz_url}/quiz-async")
print("\nهلأ شغلي: uvicorn main:app --reload --port 8000")
