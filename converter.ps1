# Input and output file paths
$inputFile = "input.html"
$outputFile = "output.html"

# Function to convert image to base64
function Convert-ImageToBase64 {
    param (
        [string]$imagePath
    )
    $mimeType = (Get-Item $imagePath).Extension -replace '^\.', ''
    $base64Data = [Convert]::ToBase64String((Get-Content -Path $imagePath -Encoding Byte))
    return "data:image/$mimeType;base64,$base64Data"
}

# Read the input HTML file
$htmlContent = Get-Content -Path $inputFile -Raw

# Regex to find <img> tags with local src attributes
$pattern = '<img\s+[^>]*src="([^"]+)"[^>]*>'

# Replace each local image src with base64 data
$htmlContent = [regex]::Replace($htmlContent, $pattern, {
    param($match)
    $imgTag = $match.Value
    $srcPath = $match.Groups[1].Value

    # Check if the src is a local file
    if (Test-Path -Path $srcPath) {
        $base64Src = Convert-ImageToBase64 -imagePath $srcPath
        $imgTag = $imgTag -replace 'src="[^"]+"', "src=`"$base64Src`""
    }
    return $imgTag
})

# Write the modified HTML to the output file
Set-Content -Path $outputFile -Value $htmlContent

Write-Host "Conversion complete. Output saved to $outputFile"