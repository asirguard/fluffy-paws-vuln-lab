<?php
require_once 'auth.php';

// Upload mode only available to logged-in users with role 'user'
$canUpload = $isLoggedIn && $currentRole === 'user';

$uploadMode = isset($_GET['upload']) && $canUpload;
$message = "";
$uploadedPath = "";

if(isset($_POST['upload'])) {
    $targetDir = "uploads/";
    $fileName = basename($_FILES["file"]["name"]);
    $target = $targetDir . $fileName;

    if(move_uploaded_file($_FILES["file"]["tmp_name"], $target)) {
        $uploadedPath = $target;
        $uploadMode = true;
    } else {
        $message = "Upload failed";
        $uploadMode = true;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pentest Lab — Ethical Hacking Practice</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

<!-- HEADER -->
<header class="header">
    <div class="header__container">
        <div class="header__logo">
            <img src="images/logo.png" alt="">
        </div>

        <div class="header__actions">
            <?php if ($isLoggedIn): ?>
                <span class="btn" style="cursor:default; opacity:0.85;"><?php echo htmlspecialchars($currentUsername); ?></span>
                <a href="dashboard.php" class="btn">Dashboard</a>
            <?php else: ?>
                <a href="login.php" class="btn">Log In</a>
                <a href="register.php" class="btn">Sign Up</a>
            <?php endif; ?>
        </div>
    </div>
</header>

<!-- MAIN -->
<main class="main">

    <!-- HERO -->
    <section class="hero <?php echo $uploadMode ? 'hero-upload' : ''; ?>">
        <div class="hero__content">

            <?php if(!$uploadMode): ?>

                <h1>Upload & Share Your Cats Photos</h1>
                <?php if ($canUpload): ?>
                    <a href="?upload=1" class="btn-hero">Upload Your Cat Pics</a>
                <?php elseif ($isLoggedIn && $currentRole === 'admin'): ?>
                    <!-- Admin sees the page but not the upload button -->
                <?php else: ?>
                    <a href="login.php" class="btn-hero">Log In to Upload</a>
                <?php endif; ?>

            <?php else: ?>

                <?php if($uploadedPath): ?>
                    <h1>Uploaded: <a href="<?php echo $uploadedPath; ?>" style="color:#fff;"><?php echo $uploadedPath; ?></a></h1>
                <?php else: ?>
                    <h1>Now Upload Your Cat</h1>
                <?php endif; ?>

                <?php if($message): ?>
                    <p class="upload-message"><?php echo $message; ?></p>
                <?php endif; ?>

                <form method="post" enctype="multipart/form-data" class="upload-form">

                    <!-- hidden real input -->
                    <input type="file" name="file" id="fileInput" required hidden>

                    <div class="buttons">
                        <!-- fake styled file button -->
                        <label for="fileInput" class="btn-hero">Choose File</label>

                        <!-- upload button -->
                        <input type="submit" name="upload" value="Upload" class="btn-hero">
                    </div>

                </form>

            <?php endif; ?>

        </div>
    </section>

    <!-- SUB MENU -->
    <div class="sub-menu">
        <div class="sub-menu__item">
            <img src="images/icon1.png" alt="">
            <span>Browse Cute Cats</span>
        </div>
        <div class="sub-menu__item">
            <img src="images/icon2.png" alt="">
            <span>Create Album</span>
        </div>
        <div class="sub-menu__item">
            <img src="images/icon3.png" alt="">
            <span>Community</span>
        </div>
    </div>

    <!-- CONTENT -->
    <section class="content">
        <div class="content__inner">

            <div class="gallery">
                <img src="images/cat1.jpg" alt="">
                <img src="images/cat2.jpg" alt="">
                <img src="images/cat3.jpg" alt="">
                <img src="images/cat4.jpg" alt="">
                <img src="images/cat5.jpg" alt="">
            </div>

            <div class="view-more">
                <a href="#" class="btn-view">View More</a>
            </div>

        </div>
    </section>

</main>

<!-- FOOTER -->
<footer class="footer">
    <p>All rights reserved © ASIRGUARD</p>
</footer>

</body>
</html>
