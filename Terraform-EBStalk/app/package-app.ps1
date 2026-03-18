param (
    [Parameter(Mandatory=$true)]
    [string]$VersionLabel,
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

$ErrorActionPreference = "Stop"

$AppDir = $PSScriptRoot
$DistDir = Join-Path $AppDir "dist"
$StagingDir = Join-Path $DistDir "staging"
$ZipPath = Join-Path $DistDir "app.zip"

Write-Host "--- Packaging Application Version: $VersionLabel for $AppName ---"

# 1. Clean and create directories
if (Test-Path $DistDir) { Remove-Item -Path $DistDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null

# 2. Identify the source JAR
# Matches patterns like my-app-v1.jar, my-app-v1-SNAPSHOT.jar, etc.
$JarPattern = "my-app-$VersionLabel*.jar"
$SourceJar = Get-ChildItem -Path $AppDir -Filter $JarPattern | Select-Object -First 1

if (-not $SourceJar) {
    throw "Could not find a JAR matching pattern: $JarPattern in $AppDir"
}

Write-Host "Using source JAR: $($SourceJar.Name)"

# 3. Copy files to staging
Copy-Item -Path $SourceJar.FullName -Destination (Join-Path $StagingDir "app.jar") -Force
Copy-Item -Path (Join-Path $AppDir "Procfile") -Destination (Join-Path $StagingDir "Procfile") -Force

# 4. Create ZIP
# Using Compress-Archive (built-in to PowerShell)
# We want the contents of staging/ at the root of the ZIP
Compress-Archive -Path "$StagingDir\*" -DestinationPath $ZipPath -Force

Write-Host "Success! Artifact created at: $ZipPath"

# 5. Upload to Default EB S3 Bucket and Create Version
$S3Bucket = "elasticbeanstalk-us-east-1-911287867452"
$S3Key = "$AppName-$VersionLabel.zip"

Write-Host "Uploading to S3: s3://$S3Bucket/$S3Key ..."
aws s3 cp $ZipPath "s3://$S3Bucket/$S3Key"

Write-Host "Creating Beanstalk Application Version: $VersionLabel ..."
aws elasticbeanstalk create-application-version `
    --application-name $AppName `
    --version-label $VersionLabel `
    --source-bundle S3Bucket=$S3Bucket,S3Key=$S3Key `
    --no-auto-create-application

Write-Host "--- Pre-Bootstrap Complete ---"
