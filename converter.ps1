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

# Function to update progress
function Update-Progress {
    param (
        [int]$processed,
        [int]$total
    )
    $progress = [math]::Round(($processed / $total) * 100, 2)
    Write-Progress -Activity "Converting Images" -Status "$progress% Complete" -PercentComplete $progress
}

# Process each image match manually
foreach ($match in $imageMatches) {
    if ($match.Groups[1].Value -eq "content" -or $match.Groups[1].Value -eq "background") {
        # CSS url() match
        $cssProperty = $match.Groups[1].Value
        $srcPath = $match.Groups[2].Value
    } else {
        # <img> tag match
        $srcPath = $match.Groups[1].Value
    }

    # Ensure the image exists
    if (Test-Path -Path $srcPath) {
        $base64Src = Convert-ImageToBase64 -imagePath $srcPath
        if ($match.Groups[1].Value -eq "content" -or $match.Groups[1].Value -eq "background") {
            # Replace CSS url()
            $replacement = "$cssProperty`: url(`"$base64Src`")"
        } else {
            # Replace <img> src
            $replacement = $match.Value -replace 'src="[^"]+"', "src=`"$base64Src`""
        }
        $htmlContent = $htmlContent -replace [regex]::Escape($match.Value), $replacement
    }

    # Update progress
    $processedImages++
    Update-Progress -processed $processedImages -total $totalImages
}

# Write the modified HTML to the output file
Set-Content -Path $outputFile -Value $htmlContent -Encoding UTF8

Write-Host "Conversion complete. Output saved to '$outputFile'"