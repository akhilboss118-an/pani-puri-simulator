# Regenerate the Hindi/Hinglish customer voice lines with Eleven Labs.
# The key is read from the environment and is NEVER stored in this repository:
#   $env:ELEVENLABS_API_KEY = "<your key>"
#   .\tools\tts\generate_dialogues.ps1
# Requires ffmpeg on PATH (MP3 from Eleven Labs is converted to OGG for Godot).

$ErrorActionPreference = "Stop"
$key = $env:ELEVENLABS_API_KEY
if (-not $key) { throw "ELEVENLABS_API_KEY is not set" }

$project = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$out = Join-Path $project "assets\audio\dialogues"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$voices = @{
    male   = "CwhRBWXzGAHq8TQ4Fs17"   # Roger - laid-back, casual
    female = "cgSgspJ2msm6clMCkdW9"   # Jessica - playful, bright
}

$lines = @(
    @{ id = "order_basic";    voice = "male";   text = "Bhaiya, ek pani puri dena na!" },
    @{ id = "order_pani";     voice = "male";   text = "Bhaiya, thoda pyaas dalo!" },
    @{ id = "order_spicy";    voice = "male";   text = "Bhaiya, thoda teekha bana dena!" },
    @{ id = "order_mild";     voice = "male";   text = "Bhaiya, mild bana dena, please!" },
    @{ id = "order_sweet";    voice = "female"; text = "Bhaiya, meethi chutney thoda kam!" },
    @{ id = "order_onion";    voice = "male";   text = "Bhaiya, pyaz thoda extra dalo!" },
    @{ id = "order_no_onion"; voice = "female"; text = "Bhaiya, pyaz bilkul mat dalo!" },
    @{ id = "hurry";          voice = "male";   text = "Bhaiya, jaldi karna, der ho rahi hai!" },
    @{ id = "vip";            voice = "male";   text = "Special order hai, bhaiya! VIP wala!" },
    @{ id = "regular";        voice = "male";   text = "Bhaiya, wahi purana order!" },
    @{ id = "diwali";         voice = "female"; text = "Shubh Diwali, bhaiya! Puri extra dalo!" },
    @{ id = "holi";           voice = "female"; text = "Holi hai, range mein puri do!" },
    @{ id = "rain";           voice = "male";   text = "Baarish hai, garam garam pani dalo!" },
    @{ id = "serve_perfect";  voice = "male";   text = "Wah bhaiya, bilkul perfect!" },
    @{ id = "serve_good";     voice = "female"; text = "Shukriya bhaiya, maza aa gaya!" },
    @{ id = "serve_bad";      voice = "male";   text = "Bhaiya, yeh to theek nahi hua!" },
    @{ id = "walkout";        voice = "male";   text = "Bas bhaiya, ab main chalta hoon!" },
    @{ id = "tutorial";       voice = "male";   text = "Ek puri, bas! Seekha do bhaiya." }
)

$temp = [IO.Path]::GetTempPath()
foreach ($line in $lines) {
    $bodyObj = @{
        text = $line.text
        model_id = "eleven_multilingual_v2"
        voice_settings = @{
            stability = 0.45
            similarity_boost = 0.78
            style = 0.18
            use_speaker_boost = $true
        }
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($bodyObj | ConvertTo-Json -Depth 5))
    $url = "https://api.elevenlabs.io/v1/text-to-speech/" + $voices[$line.voice]
    $mp3 = Join-Path $temp ("pani_" + $line.id + ".mp3")
    $ogg = Join-Path $out ($line.id + ".ogg")
    try {
        Invoke-WebRequest -Uri $url -Method Post `
            -Headers @{ "xi-api-key" = $key; "Accept" = "audio/mpeg" } `
            -ContentType "application/json" -Body $bytes `
            -OutFile $mp3 -TimeoutSec 120
        & ffmpeg -y -loglevel error -i $mp3 -c:a libvorbis -q:a 4 $ogg
        Write-Output ("OK " + $line.id)
    } catch {
        Write-Output ("FAIL " + $line.id + " : " + $_.Exception.Message)
    } finally {
        if (Test-Path $mp3) { Remove-Item $mp3 -Force }
    }
    Start-Sleep -Milliseconds 350
}
Write-Output "DONE"
