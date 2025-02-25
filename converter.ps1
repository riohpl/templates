# Input and output file paths
$inputFile = "index.html"
$outputFile = "output.html"

# Function to convert image to base64
function Convert-ImageToBase64 {
    param (
        [string]$imagePath
    )
    if (-not (Test-Path -Path $imagePath)) {
        Write-Host "Warning: Image '$imagePath' not found, skipping."
        return $imagePath  # Return original path if image not found
    }

    $mimeType = switch ([System.IO.Path]::GetExtension($imagePath).ToLower()) {
        ".png"  { "image/png" }
        ".jpg"  { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".gif"  { "image/gif" }
        ".svg"  { "image/svg+xml" }
        ".webp" { "image/webp" }
        default { "application/octet-stream" }  # Fallback MIME type
    }

    $base64Data = [Convert]::ToBase64String((Get-Content -Path $imagePath -Encoding Byte))
    return "data:$mimeType;base64,$base64Data"
}

# Read the input HTML file
$htmlContent = Get-Content -Path $inputFile -Raw

# Find all image paths in the HTML content
$imageMatches = [regex]::Matches($htmlContent, '<img\s+[^>]*src="([^"]+)"') + [regex]::Matches($htmlContent, '(content|background)\s*:\s*url\(["'']?([^)"'']+)["'']?\)')

# Total number of images to process
$totalImages = $imageMatches.Count
$processedImages = 0

# Replace <img> tag src attributes with base64
$htmlContent = [regex]::Replace($htmlContent, '<img\s+[^>]*src="([^"]+)"', {
    param($match)
    $srcPath = $match.Groups[1].Value

    # Ensure the image exists
    if (Test-Path -Path $srcPath) {
        $base64Src = Convert-ImageToBase64 -imagePath $srcPath
        $processedImages++
        $progress = [math]::Round(($processedImages / $totalImages) * 100, 2)
        Write-Progress -Activity "Converting Images" -Status "$progress% Complete" -PercentComplete $progress
        return $match.Value -replace 'src="[^"]+"', "src=`"$base64Src`""
    }
    return $match.Value  # Keep original if file not found
})

# Replace CSS content and background image URLs
$htmlContent = [regex]::Replace($htmlContent, '(content|background)\s*:\s*url\(["'']?([^)"'']+)["'']?\)', {
    param($match)
    $cssProperty = $match.Groups[1].Value
    $srcPath = $match.Groups[2].Value

    # Ensure the image exists
    if (Test-Path -Path $srcPath) {
        $base64Src = Convert-ImageToBase64 -imagePath $srcPath
        $processedImages++
        $progress = [math]::Round(($processedImages / $totalImages) * 100, 2)
        Write-Progress -Activity "Converting Images" -Status "$progress% Complete" -PercentComplete $progress
        return "$cssProperty`: url(`"$base64Src`")"
    }
    return $match.Value  # Keep original if file not found
})

# Write the modified HTML to the output file
Set-Content -Path $outputFile -Value $htmlContent -Encoding UTF8

Write-Host "Conversion complete. Output saved to '$outputFile'"