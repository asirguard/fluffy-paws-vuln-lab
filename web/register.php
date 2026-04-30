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
    <title>Sign Up — Fluffy Paws</title>
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
            <a href="login.php" class="btn">Log In</a>
        </div>
    </div>
</header>

<!-- AUTH HERO -->
<section class="auth-hero">
    <div class="auth-box">
        <h2>Join Fluffy Paws</h2>
        <p class="auth-subtitle">Create your account and share your cats</p>

        <div class="auth-error" id="errorBox"></div>

        <div class="auth-field">
            <label for="username">Username</label>
            <input type="text" id="username" placeholder="e.g. alice" autocomplete="username">
        </div>

        <div class="auth-field">
            <label for="email">Email</label>
            <input type="email" id="email" placeholder="alice@example.com" autocomplete="email">
        </div>

        <div class="auth-field">
            <label for="password">Password</label>
            <input type="password" id="password" placeholder="••••••••" autocomplete="new-password">
        </div>

        <button class="auth-submit" id="submitBtn" onclick="doRegister()">Create Account</button>

        <div class="auth-switch">
            Already have an account? <a href="login.php">Log In</a>
        </div>
    </div>
</section>

<!-- FOOTER -->
<footer class="footer">
    <p>All rights reserved © ASIRGUARD</p>
</footer>

<script>
async function doRegister() {
    const username = document.getElementById('username').value.trim();
    const email    = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const errorBox = document.getElementById('errorBox');
    const btn      = document.getElementById('submitBtn');

    errorBox.classList.remove('visible');

    if (!username || !email || !password) {
        errorBox.textContent = 'Please fill in all fields.';
        errorBox.classList.add('visible');
        return;
    }

    btn.textContent = 'Creating account…';
    btn.disabled = true;

    try {
        // VULN #4 — Mass Assignment:
        // The API spreads req.body directly into the User model.
        // Any extra field sent here (e.g. "role": "admin") will be saved to MongoDB.
        // This form only sends the 3 expected fields — but nothing stops an attacker
        // from modifying the request (Burp, curl) and injecting "role": "admin".
        const res = await fetch('http://127.0.0.1:3000/api/auth/register', {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password })
        });

        const data = await res.json();

        if (!res.ok) {
            throw new Error(data.error || 'Registration failed');
        }

        // Registration successful — redirect to login
        window.location.href = 'login.php?registered=1';

    } catch (err) {
        errorBox.textContent = err.message;
        errorBox.classList.add('visible');
        btn.textContent = 'Create Account';
        btn.disabled = false;
    }
}

document.addEventListener('keydown', e => {
    if (e.key === 'Enter') doRegister();
});
</script>

</body>
</html>
