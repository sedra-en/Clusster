import requests
import json
 
# ضعي None لو ما بدك تبعتي صوت أو صورة
audio_path = r"C:\Users\Sedra\Desktop\WhatsApp.mp4"
image_path = r"C:\Users\Sedra\Desktop\ch1_OS copy.pdf"
 
print("[INFO] Reading files...")
files = {}
 
if audio_path:
    with open(audio_path, "rb") as f:
        audio_data = f.read()
    files["audio"] = ("WhatsApp.mp4", audio_data, "audio/mp4")
    print(f"[INFO] Audio size: {len(audio_data)/1024:.1f} KB")
 
if image_path:
    with open(image_path, "rb") as f:
        image_data = f.read()
    files["image"] = ("document.pdf", image_data, "application/pdf")
    print(f"[INFO] PDF size  : {len(image_data)/1024:.1f} KB")
 
if not files:
    print("[ERROR] لازم تبعتي صوت أو صورة على الأقل!")
    exit(1)
 
print("[INFO] Sending request...")
 
response = requests.post(
    "http://127.0.0.1:8000/process",
    files=files,
    timeout=7200
)
 
print(f"\nStatus: {response.status_code}")
result = response.json()
 
audio_len    = len(result.get("audio_text", ""))
ocr_len      = len(result.get("ocr_text", ""))
basic_len    = len(result.get("summary", {}).get("basic", ""))
standard_len = len(result.get("summary", {}).get("standard", ""))
advanced_len = len(result.get("summary", {}).get("advanced", ""))
quiz_count   = len(result.get("quiz", []))
 
print(f"نص الصوت        : {audio_len} حرف")
print(f"نص الصورة       : {ocr_len} حرف")
print(f"ملخص مختصر      : {basic_len} حرف")
print(f"ملخص عادي       : {standard_len} حرف")
print(f"ملخص مفصل       : {advanced_len} حرف")
print(f"أسئلة الكويز    : {quiz_count} سؤال")
 
output_path = r"C:\Users\Sedra\Desktop\result.txt"
with open(output_path, "w", encoding="utf-8") as f:
    f.write("=== نص الصوت ===\n")
    f.write(result.get("audio_text", "") + "\n\n")
    f.write("=== نص الصورة ===\n")
    f.write(result.get("ocr_text", "") + "\n\n")
    f.write("=== النص المدموج ===\n")
    f.write(result.get("merged_text", "") + "\n\n")
    f.write("=== الملخص المختصر ===\n")
    f.write(result.get("summary", {}).get("basic", "") + "\n\n")
    f.write("=== الملخص العادي ===\n")
    f.write(result.get("summary", {}).get("standard", "") + "\n\n")
    f.write("=== الملخص المفصل ===\n")
    f.write(result.get("summary", {}).get("advanced", "") + "\n\n")
    f.write("=== الكويز ===\n")
    quiz = result.get("quiz", [])
    if quiz:
        for i, q in enumerate(quiz, 1):
            q_type = q.get("type", "")
            bloom  = q.get("bloom", "")
            f.write(f"س{i} [{q_type} | {bloom}]: {q.get('question', '')}\n")
            choices = q.get("choices", {})
            for letter, text in choices.items():
                f.write(f"   {letter}) {text}\n")
            f.write(f"الجواب: {q.get('answer', '')}\n")
            f.write(f"التفسير: {q.get('explanation', '')}\n\n")
    else:
        f.write("لا يوجد أسئلة\n")
 
print(f"\n✅ تم الحفظ: {output_path}")