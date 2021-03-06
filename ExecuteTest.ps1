$CodecovVersion = "1.7.1"
$CoverletVersion = "1.4.1"

# check Codecov Token
$token = $env:CODECOV_TOKEN
if ([string]::IsNullOrEmpty($token))
{
    Write-Host "Environmental Value 'CODECOV_TOKEN' is not defined." -ForegroundColor Red
    exit -1
}

Write-Host "Environmental Value 'CODECOV_TOKEN' is ${token}." -ForegroundColor Green

$Current = Get-Location
$CoverageDir = Join-Path $Current CoverageResults
if (!(Test-Path "$CoverageDir"))
{
    New-Item "$CoverageDir" -ItemType Directory > $null
}

# install coverlet
dotnet tool install --global coverlet.console --version $CoverletVersion > $null
# install codecov but it is not used from test project
dotnet add test\FaceRecognitionDotNet.Tests\FaceRecognitionDotNet.Tests.csproj package Codecov --version $CodecovVersion > $null

Write-Host "Start Test and collect Coverage." -ForegroundColor Green
# https://github.com/tonerdo/coverlet/blob/master/Documentation/MSBuildIntegration.md
dotnet test test\FaceRecognitionDotNet.Tests\FaceRecognitionDotNet.Tests.csproj `
            /p:CollectCoverage=true `
            /p:CoverletOutputFormat=opencover `
            /p:Exclude="[DlibDotNet]*" `
            -c Release
Write-Host "End Test and collect Coverage." -ForegroundColor Green

$path = (dotnet nuget locals global-packages --list).Replace('info : global-packages: ', '').Trim()
$path =  Join-Path $path "codecov" | `
         Join-Path -ChildPath $CodecovVersion

if ($global:IsWindows)
{
    $path = Join-Path $path "tools\codecov.exe"
}
elseif ($global:IsLinux)
{
    $path = Join-Path $path "tools/linux-x64/codecov"
}
elseif ($global:IsMacOS)
{
    $path = Join-Path $path "tools/osx-x64/codecov"
}

& $path -f test\FaceRecognitionDotNet.Tests\coverage.opencover.xml -t $token