# Script to configure GitHub Pages to use GitHub Actions via API
# Ensure you have $env:GH_TOKEN set before running

if (-not $env:GH_TOKEN) {
    Write-Error "Environment variable GH_TOKEN not found. Please set it using: `$env:GH_TOKEN = 'your_token'"
    exit 1
}

$params = @{
    Uri = "https://api.github.com/repos/gugafer/gugafer.github.io/pages"
    Method = "Put"
    Headers = @{
        "Authorization" = "Bearer $($env:GH_TOKEN)"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    Body = '{"build_type":"workflow"}'
    ContentType = "application/json"
}

try {
    Write-Host "Updating GitHub Pages configuration to 'workflow' (GitHub Actions)..." -ForegroundColor Cyan
    $response = Invoke-RestMethod @params
    Write-Host "Success! GitHub Pages is now configured to use GitHub Actions." -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Error "Failed to update GitHub Pages. Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $body = $reader.ReadToEnd()
        Write-Host "Response Body: $body" -ForegroundColor Red
    }
}
