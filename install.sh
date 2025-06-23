#!/bin/bash

main() {
    echo "--- BUNNI MAC INSTALLER ---"

    echo "Getting latest Mac Version"
    json=$(curl -s "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
    local version=$(echo "$json" | grep -o '"clientVersionUpload":"[^"]*' | grep -o '[^"]*$')

    if [ "$version" != "version-6cd64f0a23fc4462" ]; then
        echo "Bunni Mac is not updated for the latest Version. Stopping Installation"
        exit 1
    fi

    if pgrep -x "RobloxPlayer" > /dev/null; then
        pkill -9 RobloxPlayer
    fi

    echo "Reinstalling Roblox"
    [ -d "/Applications/Roblox.app" ] && rm -rf "/Applications/Roblox.app"
    curl -L "http://setup.rbxcdn.com/mac/$version-RobloxPlayer.zip" -o "./RobloxPlayer.zip"
    unzip -o -q "./RobloxPlayer.zip"
    mv "./RobloxPlayer.app" "/Applications/Roblox.app"
    rm "./RobloxPlayer.zip"
    xattr -c /Applications/Roblox.app
    codesign --remove-signature "/Applications/Roblox.app/Contents/MacOS/RobloxPlayer"

    if [ -d "/Applications/Bunni.app" ]; then
        echo "Deleting existing Bunni.app..."
        rm -rf "/Applications/Bunni.app"
    fi

    echo "Downloading Bunni UI..."
    curl -L "https://cdn.discordapp.com/attachments/1361649575206719618/1386778857259929762/Bunni_0.1.0_aarch64.dmg?ex=685af1f4&is=6859a074&hm=c834347a0a4f9d9e84723fa547b3dae76e3b39a9cf58a1f0a6c447947a7e4dc0&" -o "./Bunni.dmg"

    echo "Starting DMG..."
    MOUNT_OUTPUT=$(hdiutil attach "./Bunni.dmg" -nobrowse)
    MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/[^ ]*')

    if [ -z "$MOUNT_POINT" ]; then
        echo "Failed to mount DMG."
        exit 1
    fi

    echo "Opening Finder window..."
    open "$MOUNT_POINT"

    echo "Waiting for user to finish installation..."
    while [ ! -d "/Applications/Bunni.app" ]; do
        sleep 2
    done

    echo "Downloading dylib..."
    curl -L "https://cdn.discordapp.com/attachments/1319617687814406166/1386803214585823356/libbunnimac.dylib?ex=685b08a3&is=6859b723&hm=4f1b22bec1bfc46b4abeb602f8df55c68953d5e4e6dd4b66873fadc4a75cb5d9&" -o "./libbunnimac.dylib"

    echo "Installing dylib into Bunni.app..."
    LIB_TARGET="/Applications/Bunni.app/Contents/MacOS/libbunnimac.dylib"
    cp "./libbunnimac.dylib" "$LIB_TARGET"
    chmod +x "$LIB_TARGET"

    echo "Cleaning up..."
    hdiutil detach "$MOUNT_POINT" -quiet
    rm "./Bunni.dmg"
    rm "./libbunnimac.dylib"

    echo "Checking for Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    echo "Installing required libraries..."
    brew install xxhash lz4 zstd cpr cryptopp openssl curl

    HOMEBREW_PREFIX=$(brew --prefix)

    echo "Required .dylibs are located in: $HOMEBREW_PREFIX/lib"

    echo "Installation complete."
}

main
