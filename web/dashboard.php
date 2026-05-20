<?php
require_once 'auth.php';

// Auth guard — no token → redirect to login
if (!$isLoggedIn) {
    header('Location: login.php');
    exit;
}

// Convenience aliases for this page
$role     = $currentRole;
$username = $currentUsername;
$userId   = $currentUserId;
$payload  = $jwtPayload;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard — Fluffy Paws</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

<!-- HEADER -->
<header class="header">
    <div class="header__container">
        <div class="header__logo">
            <a href="index.php"><img src="images/logo.png" alt="Fluffy Paws"></a>
        </div>
        <div class="header__actions">
            <span class="btn" style="cursor:default; opacity:0.85;">
                <?php echo htmlspecialchars($username); ?>
                &nbsp;
                <span class="dash-badge dash-badge--<?php echo $role === 'admin' ? 'admin' : 'user'; ?>">
                    <?php echo htmlspecialchars($role); ?>
                </span>
            </span>
            <button class="dash-logout" onclick="doLogout()">Log Out</button>
        </div>
    </div>
</header>

<!-- DASH HERO -->
<section class="dash-hero">
    <div class="dash-hero__inner">
        <?php if ($role === 'admin'): ?>
            <h1>Admin Panel 🛡️</h1>
            <p>Full system access — manage users, content, and settings</p>
        <?php else: ?>
            <h1>Welcome back, <?php echo htmlspecialchars($username); ?>! 🐾</h1>
            <p>Your personal cat dashboard</p>
        <?php endif; ?>
    </div>
</section>

<!-- DASH BODY -->
<main class="dash-body">

    <?php if ($role === 'admin'): ?>
    <!-- ── ADMIN VIEW ───────────────────────────────────────── -->

    <h2 class="dash-section-title">Admin Tools</h2>
    <div class="dash-cards">

        <a href="#" class="dash-card">
            <div class="dash-card__icon">👥</div>
            <div class="dash-card__title">Manage Users</div>
            <div class="dash-card__desc">View, edit, or delete user accounts</div>
        </a>

        <a href="#" class="dash-card">
            <div class="dash-card__icon">🖼️</div>
            <div class="dash-card__title">All Uploads</div>
            <div class="dash-card__desc">Browse and moderate all uploaded content</div>
        </a>

        <a href="#" class="dash-card">
            <div class="dash-card__icon">📊</div>
            <div class="dash-card__title">Statistics</div>
            <div class="dash-card__desc">Platform activity and usage metrics</div>
        </a>

        <a href="#" class="dash-card">
            <div class="dash-card__icon">⚙️</div>
            <div class="dash-card__title">Settings</div>
            <div class="dash-card__desc">System configuration and feature flags</div>
        </a>

    </div>

    <h2 class="dash-section-title">Debug Info
        <span style="font-size:12px; font-weight:400; color:#c0392b;">
            [VULN #9 — Excessive Data Exposure]
        </span>
    </h2>

    <!-- VULN #9 — Debug panel exposes raw JWT payload on the page.
         Combined with VULN #7 (no signature check), an attacker who can read
         this page (XSS, screenshot) gets the full decoded token structure. -->
    <div style="background:#fff3cd; border:1px solid #ffc107; border-radius:10px; padding:20px; font-family:monospace; font-size:13px; color:#333;">
        <strong>JWT Payload (decoded, no signature check):</strong><br><br>
        <?php
        // VULN: raw payload dumped to page — never do this in production
        echo htmlspecialchars(json_encode($payload ?? [], JSON_PRETTY_PRINT));
        ?>
    </div>

    <?php else: ?>
    <!-- ── USER VIEW ────────────────────────────────────────── -->

    <h2 class="dash-section-title">My Account</h2>
    <div class="dash-cards">

        <a href="index.php?upload=1" class="dash-card">
            <div class="dash-card__icon">📤</div>
            <div class="dash-card__title">Upload Cat Photo</div>
            <div class="dash-card__desc">Share a new photo with the community</div>
        </a>

        <a href="#" class="dash-card">
            <div class="dash-card__icon">🖼️</div>
            <div class="dash-card__title">My Uploads</div>
            <div class="dash-card__desc">Browse your uploaded photos</div>
        </a>

        <a href="#" class="dash-card">
            <div class="dash-card__icon">👤</div>
            <div class="dash-card__title">My Profile</div>
            <!-- VULN #1 — BOLA: profile URL exposes user ID.
                 Attacker can change the ID to access other users' profiles. -->
            <div class="dash-card__desc">
                User ID: <code><?php echo htmlspecialchars($userId); ?></code>
            </div>
        </a>

        <a href="#" class="dash-card">
            <div class="dash-card__icon">⭐</div>
            <div class="dash-card__title">Favorites</div>
            <div class="dash-card__desc">Cats you've liked and saved</div>
        </a>

    </div>

    <?php endif; ?>

</main>

<!-- FOOTER -->
<footer class="footer">
    <p>All rights reserved © ASIRGUARD</p>
</footer>

<script>
function doLogout() {
    // Delete cookie by expiring it
    document.cookie = 'fp_token=; path=/; max-age=0';
    window.location.href = 'index.php';
}
</script>

</body>
</html>
