Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Periodontal Recall AI - System Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results = @()

# ── Python ──────────────────────────────────────────────────────────────────
try {
    $pyVer = & python --version 2>&1
    $results += [PSCustomObject]@{ Tool="Python";        Status="FOUND";   Version=$pyVer;            Required="3.11+" }
} catch {
    $results += [PSCustomObject]@{ Tool="Python";        Status="MISSING"; Version="Not installed";   Required="3.11+" }
}

# ── pip ──────────────────────────────────────────────────────────────────────
try {
    $pipVer = & pip --version 2>&1
    $results += [PSCustomObject]@{ Tool="pip";           Status="FOUND";   Version=($pipVer -split ' ')[1]; Required="Any" }
} catch {
    $results += [PSCustomObject]@{ Tool="pip";           Status="MISSING"; Version="Not installed";   Required="Any" }
}

# ── MySQL ────────────────────────────────────────────────────────────────────
$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if ($mysqlPath) {
    $mysqlVer = & mysql --version 2>&1
    $results += [PSCustomObject]@{ Tool="MySQL";         Status="FOUND";   Version=$mysqlVer;         Required="8.0+" }
} else {
    $results += [PSCustomObject]@{ Tool="MySQL";         Status="MISSING"; Version="Not installed";   Required="8.0+" }
}

# ── Flutter ──────────────────────────────────────────────────────────────────
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterPath) {
    $flutterVer = (& flutter --version 2>&1 | Select-Object -First 1)
    $results += [PSCustomObject]@{ Tool="Flutter";       Status="FOUND";   Version=$flutterVer;       Required="3.3+" }
} else {
    $results += [PSCustomObject]@{ Tool="Flutter";       Status="MISSING"; Version="Not installed";   Required="3.3+" }
}

# ── Dart ─────────────────────────────────────────────────────────────────────
$dartPath = Get-Command dart -ErrorAction SilentlyContinue
if ($dartPath) {
    $dartVer = & dart --version 2>&1
    $results += [PSCustomObject]@{ Tool="Dart";          Status="FOUND";   Version=$dartVer;          Required="3.0+" }
} else {
    $results += [PSCustomObject]@{ Tool="Dart";          Status="MISSING"; Version="Not installed";   Required="3.0+" }
}

# ── Git ──────────────────────────────────────────────────────────────────────
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if ($gitPath) {
    $gitVer = & git --version 2>&1
    $results += [PSCustomObject]@{ Tool="Git";           Status="FOUND";   Version=$gitVer;           Required="Any" }
} else {
    $results += [PSCustomObject]@{ Tool="Git";           Status="MISSING"; Version="Not installed";   Required="Any" }
}

# ── Docker ───────────────────────────────────────────────────────────────────
$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerPath) {
    $dockerVer = & docker --version 2>&1
    $results += [PSCustomObject]@{ Tool="Docker";        Status="FOUND";   Version=$dockerVer;        Required="Optional" }
} else {
    $results += [PSCustomObject]@{ Tool="Docker";        Status="MISSING"; Version="Not installed";   Required="Optional" }
}

# ── Android Studio / SDK ─────────────────────────────────────────────────────
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) { $androidHome = $env:ANDROID_SDK_ROOT }
if ($androidHome -and (Test-Path $androidHome)) {
    $results += [PSCustomObject]@{ Tool="Android SDK";   Status="FOUND";   Version=$androidHome;      Required="For emulator" }
} else {
    $results += [PSCustomObject]@{ Tool="Android SDK";   Status="MISSING"; Version="ANDROID_HOME not set"; Required="For emulator" }
}

# ── Java (needed by Android Studio) ─────────────────────────────────────────
$javaPath = Get-Command java -ErrorAction SilentlyContinue
if ($javaPath) {
    $javaVer = & java -version 2>&1 | Select-Object -First 1
    $results += [PSCustomObject]@{ Tool="Java (JDK)";    Status="FOUND";   Version=$javaVer;          Required="11+ (Android)" }
} else {
    $results += [PSCustomObject]@{ Tool="Java (JDK)";    Status="MISSING"; Version="Not installed";   Required="11+ (Android)" }
}

# ── Check Python packages already installed ───────────────────────────────
$pipList = & pip list 2>&1 | Out-String
$packages = @("flask","flask-jwt-extended","sqlalchemy","pymysql","bcrypt","tensorflow","keras","opencv-python-headless","numpy","scikit-learn","gunicorn")
Write-Host "`n--- Python Package Check ---`n" -ForegroundColor Cyan
foreach ($pkg in $packages) {
    if ($pipList -match $pkg) {
        Write-Host "  [OK]      $pkg" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $pkg" -ForegroundColor Red
    }
}

# ── Print table ──────────────────────────────────────────────────────────────
Write-Host "`n--- System Tools ---`n" -ForegroundColor Cyan
foreach ($r in $results) {
    if ($r.Status -eq "FOUND") {
        Write-Host ("  [OK]      {0,-15} {1}" -f $r.Tool, $r.Version) -ForegroundColor Green
    } else {
        Write-Host ("  [MISSING] {0,-15} Required: {1}" -f $r.Tool, $r.Required) -ForegroundColor Red
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────
$missing  = $results | Where-Object { $_.Status -eq "MISSING" -and $_.Required -notmatch "Optional" }
$optional = $results | Where-Object { $_.Status -eq "MISSING" -and $_.Required -match "Optional" }

Write-Host "`n========================================" -ForegroundColor Cyan
if ($missing.Count -eq 0) {
    Write-Host " All required tools are installed!" -ForegroundColor Green
} else {
    Write-Host (" {0} required tool(s) MISSING:" -f $missing.Count) -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host ("   - {0}  (need: {1})" -f $m.Tool, $m.Required) -ForegroundColor Yellow
    }
}
if ($optional.Count -gt 0) {
    Write-Host "`n Optional (not blocking):" -ForegroundColor DarkYellow
    foreach ($o in $optional) {
        Write-Host ("   - {0}" -f $o.Tool) -ForegroundColor DarkYellow
    }
}
Write-Host "========================================`n" -ForegroundColor Cyan
