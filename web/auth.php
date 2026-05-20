<?php
/**
 * auth.php — shared JWT decode helper
 *
 * Intentionally does NOT verify the signature — VULN #7.
 * Include this file to get $isLoggedIn, $currentRole, $currentUsername, $currentUserId, $jwtPayload.
 */

$isLoggedIn      = false;
$currentRole     = '';
$currentUsername = '';
$currentUserId   = '';
$jwtPayload      = null;

if (!empty($_COOKIE['fp_token'])) {
    $parts = explode('.', $_COOKIE['fp_token']);
    if (count($parts) === 3) {
        // Base64url → Base64 → JSON
        $padded  = str_pad(
            strtr($parts[1], '-_', '+/'),
            (int) ceil(strlen($parts[1]) / 4) * 4,
            '=',
            STR_PAD_RIGHT
        );
        $payload = json_decode(base64_decode($padded), true);

        if ($payload && isset($payload['role'])) {
            $isLoggedIn      = true;
            $currentRole     = $payload['role'];
            $currentUsername = $payload['username'] ?? '';
            $currentUserId   = $payload['id']       ?? '';
            $jwtPayload      = $payload;
        }
    }
}
