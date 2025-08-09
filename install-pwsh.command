#!/bin/bash
clear

# ⛔ Ctrl+C 차단
trap 'echo -e "\n⚠ Ctrl+C는 사용할 수 없습니다. 설치를 마저 진행해주세요.";' SIGINT

# ✅ 아키텍처 확인
archtype=$(uname -m)
if [[ "$archtype" == "powerpc"* || "$archtype" == "ppc"* ]]; then
    echo "❌ PowerPC는 PowerShell을 지원하지 않습니다."
    exit 1
fi
pkgarch="osx-$( [ "$archtype" = "arm64" ] && echo "arm64" || echo "x64" ).pkg"

# ✅ 현재 설치된 pwsh 버전
if command -v pwsh &>/dev/null; then
    installed=$(pwsh -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    shell_cmd="pwsh"
elif command -v powershell &>/dev/null; then
    installed=$(powershell -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null)
    shell_cmd="powershell"
else
    installed=""
    shell_cmd=""
fi

# ✅ 최신 릴리스 가져오기
releases=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases)
stable_url=$(echo "$releases" | grep -B 20 "$pkgarch" | grep '"browser_download_url":' | grep "$pkgarch" | grep -v 'preview\|rc' | head -n1 | cut -d '"' -f 4)
stable_version=$(echo "$stable_url" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

# ✅ preview fallback
if [ -z "$stable_url" ]; then
    echo "ℹ️ 정식 릴리스에 .pkg가 없어 preview로 전환합니다."
    stable_url=$(echo "$releases" | grep -B 20 "$pkgarch" | grep '"browser_download_url":' | grep "$pkgarch" | head -n1 | cut -d '"' -f 4)
    stable_version=$(echo "$stable_url" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    is_preview=true
else
    is_preview=false
fi

# ✅ 유효성 검사
if [ -z "$stable_url" ] || [ -z "$stable_version" ]; then
    echo "❌ 설치 가능한 PowerShell .pkg 파일을 찾을 수 없습니다."
    echo "➡ PowerShell을 실행합니다..."
    sleep 1
    clear
    pwsh
    exit
fi

# ✅ 버전 비교
if [ "$installed" = "$stable_version" ]; then
    echo "✅ 최신 버전($stable_version)입니다. 설치할 필요가 없습니다."
else
    echo "⚠ 현재 버전: ${installed:-없음}, 설치 대상 버전: $stable_version"
    [ "$is_preview" = true ] && echo "🔔 이 릴리스는 preview입니다."

    # ✅ 사용자 입력 루프
    while true; do
        echo -n "📦 PowerShell을 설치할까요? (Y/n): "
        if ! read yn; then
            echo -e "\n⚠ Ctrl+D는 사용할 수 없습니다. 기본값 'y'로 계속 진행합니다."
            yn="y"
        fi
        yn="${yn:-y}"  # 기본값 y

        case "$yn" in
            [Yy])
                # ✅ Homebrew로 설치됐는지 확인
                if brew list powershell &>/dev/null; then
                    echo "🍺 Homebrew 설치 감지됨. powershell 업그레이드 중..."
                    brew upgrade powershell && echo "✅ Homebrew 업그레이드 완료." || echo "❌ 업그레이드 실패."
                else
                    echo "🍺 Homebrew 설치되지 않음. .pkg 설치로 진행합니다."
                    echo "설치를 계속하시려면 비밀번호를 입력하세요."
                    sudo true && echo "✅ 권한을 얻었습니다."
                    # ✅ 구버전 powershell 감지 후 삭제
                    if command -v powershell &>/dev/null; then
                        echo "🧹 구버전 PowerShell 감지됨. 제거합니다..."
                        sudo rm -f "$(which powershell)"
                        echo "✅ PowerShell 제거 완료"
                    fi
                    fname=$(basename "$stable_url")
                    echo "⬇ 다운로드 중: $fname"
                    curl -L -o "$fname" "$stable_url"
                    echo "⚙ 설치 중..."
                    sudo installer -pkg "$fname" -target /
                    rm "$fname"
                    echo "✅ 설치 완료 및 파일 삭제됨."
                fi
                break
                ;;
            [Nn])
                echo "❌ 설치 취소됨."
                break
                ;;
            *)
                echo "⚠ 올바른 입력이 아닙니다. 다시 입력하세요."
                ;;
        esac
    done
fi

# 다시 확인
if command -v pwsh &>/dev/null; then
    installed=$(pwsh -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    shell_cmd="pwsh"
elif command -v powershell &>/dev/null; then
    installed=$(powershell -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null)
    shell_cmd="powershell"
else
    installed=""
    shell_cmd=""
fi

# ✅ 실행
echo "➡ PowerShell을 실행합니다..."
sleep 1
clear

if [ -n "$shell_cmd" ]; then
    $shell_cmd
    clear
    echo "⚠ PowerShell 세션이 종료되었습니다. 다시 실행하려면 이 스크립트를 다시 실행하세요."
    sleep 1
else
    echo "❌ 실행 가능한 PowerShell이 없습니다."
    sleep 1
fi

# 🐱 터미널에 냥캣 GIF 띄우기 (iTerm2 전용 기능, imgcat 필요)
if command -v imgcat &>/dev/null; then
    # echo -e "\n🚀 냥캣 GIF를 인터넷에서 가져오는 중...\n"
    curl -s -o /tmp/nyan.gif "https://i.namu.wiki/i/Fn9A4jerbuggM6wTrtN0ItBh3M6BHA6UM5feDn1yKlm33nwS-4MgzN6Dn_QPiM6EGsdbs9jd7Lw9OtqENkggtQ.gif"
    if [ -f /tmp/nyan.gif ]; then
        imgcat /tmp/nyan.gif
        sleep 2
        rm /tmp/nyan.gif
    fi
fi

exit