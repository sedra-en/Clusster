<?php
function sendSuccess($message, $data = null) {
    echo json_encode(["status" => "success", "message" => $message, "data" => $data]);
    exit;
}
function sendError($message, $code = 400) {
    http_response_code($code);
    echo json_encode(["status" => "error", "message" => $message]);
    exit;
}