import requests
import json
import os
import time
import urllib3
import asyncio
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

app = FastAPI()

def load_config():
    if os.path.exists("config.json"):
        with open("config.json") as f:
            return json.load(f)
    return {}

config = load_config()
WHISPER_URL        = config.get("whisper_url", "") + "/transcribe-async"
WHISPER_RESULT_URL = config.get("whisper_url", "") + "/transcribe-result"
OCR_URL            = config.get("ocr_url", "")     + "/ocr-async"
OCR_RESULT_URL     = config.get("ocr_url", "")     + "/ocr-result"
SUMMARY_URL        = config.get("summary_url", "") + "/summarize-all-async"
SUMMARY_RESULT_URL = config.get("summary_url", "") + "/summarize-result"
QUIZ_URL           = config.get("quiz_url", "")    + "/quiz-async"
QUIZ_RESULT_URL    = config.get("quiz_url", "")    + "/quiz-result"

print(f"[INFO] Whisper : {WHISPER_URL}")
print(f"[INFO] OCR     : {OCR_URL}")
print(f"[INFO] Summary : {SUMMARY_URL}")
print(f"[INFO] Quiz    : {QUIZ_URL}")

def get_session():
    session = requests.Session()
    session.verify = False
    return session

def semantic_merge(audio_text: str, ocr_text: str) -> str:
    if not audio_text and not ocr_text:
        return ""
    if not audio_text:
        return ocr_text
    if not ocr_text:
        return audio_text
    return audio_text + "\n\n" + ocr_text

def poll_job(session, result_url, job_id, label, max_attempts=200):
    for attempt in range(max_attempts):
        time.sleep(10)
        try:
            result = session.get(
                f"{result_url}/{job_id}",
                headers={"ngrok-skip-browser-warning": "true"},
                timeout=7200
            )
            data = result.json()
            status = data.get("status")
            print(f"[INFO] {label} status: {status} (attempt {attempt+1})")
            if status == "done":
                return data
            elif status == "error":
                print(f"[ERROR] {label}: {data.get('error')}")
                return None
        except Exception as e:
            print(f"[ERROR] {label} polling: {str(e)}")
    return None

async def process_whisper(audio_contents, filename):
    session = get_session()
    try:
        response = session.post(
            WHISPER_URL,
            files={"file": (filename, audio_contents, "audio/ogg")},
            headers={"ngrok-skip-browser-warning": "true"},
            timeout=7200
        )
        if response.status_code == 200:
            job_id = response.json().get("job_id")
            print(f"[INFO] Whisper job started: {job_id}")
            data = await asyncio.to_thread(poll_job, session, WHISPER_RESULT_URL, job_id, "Whisper")
            if data:
                text = data.get("transcribed_text", "")
                print(f"[INFO] Audio done: {len(text)} chars")
                return text
    except Exception as e:
        print(f"[ERROR] Audio: {str(e)}")
    return ""

async def process_ocr(image_contents, filename):
    session = get_session()
    try:
        response = session.post(
            OCR_URL,
            files={"file": (filename, image_contents, "application/pdf")},
            headers={"ngrok-skip-browser-warning": "true"},
            timeout=7200
        )
        if response.status_code == 200:
            job_id = response.json().get("job_id")
            print(f"[INFO] OCR job started: {job_id}")
            data = await asyncio.to_thread(poll_job, session, OCR_RESULT_URL, job_id, "OCR")
            if data:
                text = data.get("extracted_text", "")
                print(f"[INFO] OCR done: {len(text)} chars")
                return text
    except Exception as e:
        print(f"[ERROR] OCR: {str(e)}")
    return ""

@app.get("/")
def root():
    return {"status": "Lecture Assistant API is running!"}

@app.post("/process")
async def process_lecture(
    audio: UploadFile = File(None),
    image: UploadFile = File(None)
):
    audio_text = ""
    ocr_text = ""

    tasks = []
    if audio:
        print(f"[INFO] Processing audio: {audio.filename}")
        audio_contents = await audio.read()
        tasks.append(process_whisper(audio_contents, audio.filename))
    else:
        tasks.append(asyncio.sleep(0, result=""))

    if image:
        print(f"[INFO] Processing image/PDF: {image.filename}")
        image_contents = await image.read()
        tasks.append(process_ocr(image_contents, image.filename))
    else:
        tasks.append(asyncio.sleep(0, result=""))

    results = await asyncio.gather(*tasks)

    if audio:
        audio_text = results[0] or ""
    if image:
        ocr_text = results[1] or ""

    merged = semantic_merge(audio_text, ocr_text)
    print(f"[INFO] Merged: {len(merged)} chars")

    summary_basic = ""
    summary_standard = ""
    summary_advanced = ""
    quiz = []
    session = get_session()

    if merged:
        try:
            response = session.post(
                SUMMARY_URL,
                json={"text": merged},
                headers={"ngrok-skip-browser-warning": "true"},
                timeout=7200
            )
            if response.status_code == 200:
                job_id = response.json().get("job_id")
                data = poll_job(session, SUMMARY_RESULT_URL, job_id, "Summary")
                if data:
                    summary_basic    = data.get("basic", "")
                    summary_standard = data.get("standard", "")
                    summary_advanced = data.get("advanced", "")
        except Exception as e:
            print(f"[ERROR] Summary: {str(e)}")

    if summary_advanced:
        try:
            response = session.post(
                QUIZ_URL,
                json={"text": summary_advanced},
                headers={"ngrok-skip-browser-warning": "true"},
                timeout=7200
            )
            if response.status_code == 200:
                job_id = response.json().get("job_id")
                data = poll_job(session, QUIZ_RESULT_URL, job_id, "Quiz")
                if data:
                    quiz = data.get("questions", [])
        except Exception as e:
            print(f"[ERROR] Quiz: {str(e)}")

    return JSONResponse({
        "audio_text":  audio_text,
        "ocr_text":    ocr_text,
        "merged_text": merged,
        "summary": {
            "basic":    summary_basic,
            "standard": summary_standard,
            "advanced": summary_advanced
        },
        "quiz": quiz
    })