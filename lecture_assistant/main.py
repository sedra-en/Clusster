import requests
import json
import os
import time
import numpy as np
import re
import urllib3
import asyncio
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from pydantic import BaseModel

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

app = FastAPI()

def load_config():
    if os.path.exists("config.json"):
        with open("config.json") as f:
            return json.load(f)
    return {}

config = load_config()
WHISPER_URL        = config.get("whisper_url", "")  + "/transcribe-async"
WHISPER_RESULT_URL = config.get("whisper_url", "")  + "/transcribe-result"
OCR_URL            = config.get("ocr_url", "")      + "/ocr-async"
OCR_RESULT_URL     = config.get("ocr_url", "")      + "/ocr-result"
SUMMARY_URL        = config.get("summary_url", "")  + "/summarize-all-async"
SUMMARY_RESULT_URL = config.get("summary_url", "")  + "/summarize-result"
QUIZ_URL           = config.get("quiz_url", "")     + "/quiz-async"
QUIZ_RESULT_URL    = config.get("quiz_url", "")     + "/quiz-result"

print(f"[INFO] Whisper : {WHISPER_URL}")
print(f"[INFO] OCR     : {OCR_URL}")
print(f"[INFO] Summary : {SUMMARY_URL}")
print(f"[INFO] Quiz    : {QUIZ_URL}")

embedder = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2', device='cpu')

def get_session():
    session = requests.Session()
    session.verify = False
    return session

def split_into_segments(text, min_length=20):
    segments = []
    for line in text.split('\n'):
        line = line.strip()
        if len(line) >= min_length:
            segments.append(line)
        elif len(line) > 0 and segments:
            segments[-1] += " " + line
    return segments

def semantic_merge(audio_text: str, ocr_text: str, threshold: float = 0.4) -> str:
    if not audio_text and not ocr_text:
        return ""
    if not audio_text:
        return ocr_text
    if not ocr_text:
        return audio_text

    audio_segments = split_into_segments(audio_text)
    ocr_segments   = split_into_segments(ocr_text)

    if not audio_segments or not ocr_segments:
        return audio_text + "\n\n" + ocr_text

    audio_embeddings  = embedder.encode(audio_segments)
    ocr_embeddings    = embedder.encode(ocr_segments)
    similarity_matrix = cosine_similarity(audio_embeddings, ocr_embeddings)

    merged_parts = []
    used_ocr = set()

    for i, audio_seg in enumerate(audio_segments):
        similarities   = similarity_matrix[i]
        best_match_idx = np.argmax(similarities)
        best_score     = similarities[best_match_idx]
        if best_score >= threshold and best_match_idx not in used_ocr:
            merged_parts.append(f"{audio_seg}\n{ocr_segments[best_match_idx]}")
            used_ocr.add(best_match_idx)
        else:
            merged_parts.append(audio_seg)

    for j, ocr_seg in enumerate(ocr_segments):
        if j not in used_ocr:
            merged_parts.append(ocr_seg)

    return "\n\n".join(merged_parts)


def poll_job(session, result_url, job_id, label, max_attempts=200):
    """polling مشترك لأي job"""
    for attempt in range(max_attempts):
        time.sleep(10)
        try:
            result = session.get(
                f"{result_url}/{job_id}",
                headers={"ngrok-skip-browser-warning": "true"},
                timeout=7200
            )
            data   = result.json()
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
    """يبعت الصوت للـ Whisper ويرجع النص"""
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
            data = await asyncio.to_thread(
                poll_job, session, WHISPER_RESULT_URL, job_id, "Whisper"
            )
            if data:
                text = data.get("transcribed_text", "")
                print(f"[INFO] Audio done: {len(text)} chars")
                return text
    except Exception as e:
        print(f"[ERROR] Audio: {str(e)}")
    return ""


async def process_ocr(image_contents, filename):
    """يبعت الصورة للـ OCR ويرجع النص"""
    session = get_session()
    try:
        print(f"[INFO] PDF size: {len(image_contents)/1024:.1f} KB")
        response = session.post(
            OCR_URL,
            files={"file": (filename, image_contents, "application/pdf")},
            headers={"ngrok-skip-browser-warning": "true"},
            timeout=7200
        )
        if response.status_code == 200:
            job_id = response.json().get("job_id")
            print(f"[INFO] OCR job started: {job_id}")
            data = await asyncio.to_thread(
                poll_job, session, OCR_RESULT_URL, job_id, "OCR"
            )
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
    ocr_text   = ""

    # ── Whisper + OCR بالتوازي ────────────────────────────────────────────
    tasks = []
    if audio:
        print(f"[INFO] Processing audio: {audio.filename}")
        audio_contents = await audio.read()
        tasks.append(process_whisper(audio_contents, audio.filename))
    else:
        tasks.append(asyncio.sleep(0, result=""))  # placeholder

    if image:
        print(f"[INFO] Processing image/PDF: {image.filename}")
        image_contents = await image.read()
        tasks.append(process_ocr(image_contents, image.filename))
    else:
        tasks.append(asyncio.sleep(0, result=""))  # placeholder

    results = await asyncio.gather(*tasks)

    if audio:
        audio_text = results[0] or ""
    if image:
        ocr_text = results[1] or ""

    # ── Merge ─────────────────────────────────────────────────────────────
    print("[INFO] Merging texts...")
    merged = semantic_merge(audio_text, ocr_text)
    print(f"[INFO] Merged: {len(merged)} chars")

    summary_basic    = ""
    summary_standard = ""
    summary_advanced = ""
    quiz             = []
    session          = get_session()

    # ── Summary all levels (async) ────────────────────────────────────────
    if merged:
        print("[INFO] Summarizing all levels...")
        try:
            response = session.post(
                SUMMARY_URL,
                json={"text": merged},
                headers={"ngrok-skip-browser-warning": "true"},
                timeout=7200
            )
            if response.status_code == 200:
                job_id = response.json().get("job_id")
                print(f"[INFO] Summary job started: {job_id}")
                data = poll_job(session, SUMMARY_RESULT_URL, job_id, "Summary")
                if data:
                    summary_basic    = data.get("basic", "")
                    summary_standard = data.get("standard", "")
                    summary_advanced = data.get("advanced", "")
                    print("[INFO] Summary done!")
            else:
                print(f"[ERROR] Summary status: {response.status_code}")
        except Exception as e:
            print(f"[ERROR] Summary: {str(e)}")

    # ── Quiz (async) ──────────────────────────────────────────────────────
    if summary_advanced:
        print("[INFO] Generating quiz...")
        try:
            response = session.post(
                QUIZ_URL,
                json={"text": summary_advanced},
                headers={"ngrok-skip-browser-warning": "true"},
                timeout=7200
            )
            if response.status_code == 200:
                job_id = response.json().get("job_id")
                print(f"[INFO] Quiz job started: {job_id}")
                data = poll_job(session, QUIZ_RESULT_URL, job_id, "Quiz")
                if data:
                    quiz = data.get("questions", [])
                    print(f"[INFO] Quiz done! {len(quiz)} questions")
            else:
                print(f"[ERROR] Quiz status: {response.status_code}")
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
