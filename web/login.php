<?php
// ── Redirect if already logged in ────────────────────────────
if (!empty($_COOKIE['fp_token'])) {
    header('Location: dashboard.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Log In — Fluffy Paws</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body class="auth-wrapper">

<!-- HEADER -->
<header class="header">
    <div class="header__container">
        <div class="header__logo">
            <a href="index.php"><img src="images/logo.png" alt="Fluffy Paws"></a>
        </div>
        <div class="header__actions">
            <a href="register.php" class="btn">Sign Up</a>
        </div>
    </div>
</header>

<!-- AUTH HERO -->
<section class="auth-hero">
    <div class="auth-box">
        <h2>Welcome Back</h2>
        <p class="auth-subtitle">Log in to your Fluffy Paws account</p>

        <div class="auth-error" id="errorBox"></div>

        <div class="auth-field">
            <label for="username">Username</label>
            <input type="text" id="username" placeholder="e.g. alice" autocomplete="username">
        </div>

        <div class="auth-field">
            <label for="password">Password</label>
            <input type="password" id="password" placeholder="••••••••" autocomplete="current-password">
        </div>

        <button class="auth-submit" id="submitBtn" onclick="doLogin()">Log In</button>

        <div class="auth-switch">
            Don't have an account? <a href="register.php">Sign Up</a>
        </div>
    </div>
</section>

<!-- FOOTER -->
<footer class="footer">
    <p>All rights reserved © ASIRGUARD</p>
</footer>

<script>
async function doLogin() {
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    const errorBox = document.getElementById('errorBox');
    const btn      = document.getElementById('submitBtn');

    errorBox.classList.remove('visible');

    if (!username || !password) {
        errorBox.textContent = 'Please fill in all fields.';
        errorBox.classList.add('visible');
        return;
    }

    btn.textContent = 'Logging in…';
    btn.disabled = true;

    try {
        // VULN #12 — NoSQL Injection: username is sent as-is, no sanitization
        // VULN #10 — No rate limiting on this endpoint
        const res = await fetch('http://127.0.0.1:3000/api/auth/login', {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const data = await res.json();

        if (!res.ok) {
            throw new Error(data.error || 'Login failed');
        }

        // VULN #7 — Cookie is NOT httpOnly → XSS can steal token via document.cookie
        // VULN: No SameSite=Strict → CSRF possible
        document.cookie = `fp_token=${data.token}; path=/; max-age=86400`;

        window.location.href = 'dashboard.php';

    } catch (err) {
        errorBox.textContent = err.message;
        errorBox.classList.add('visible');
        btn.textContent = 'Log In';
        btn.disabled = false;
    }
}

document.addEventListener('keydown', e => {
    if (e.key === 'Enter') doLogin();
});
</script>

</body>
</html>
