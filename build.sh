#!/usr/bin/env bash
# Builds the Android app. Runs on GitHub (see the workflow). Nothing here needs editing.
set -euo pipefail

# 1. Create the Android project from capacitor.config.json
npx cap add android

# 2. Sign every build with the same key, so new versions install over old ones and keep your data
cp ledger.keystore android/app/ledger.keystore
python3 - <<'PY'
p = 'android/app/build.gradle'
s = open(p).read()
old = "    buildTypes {\n        release {\n            minifyEnabled false"
new = """    signingConfigs {
        release {
            storeFile file('ledger.keystore')
            storePassword 'ledgerapp'
            keyAlias 'ledger'
            keyPassword 'ledgerapp'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false"""
if old not in s:
    raise SystemExit('Could not find the release block in build.gradle')
open(p, 'w').write(s.replace(old, new, 1))
PY

# 3. App icon
npx capacitor-assets generate --android --iconBackgroundColor '#1d6a49'

# 4. Copy the web app into the project
npx cap sync android

if [ -n "${SKIP_GRADLE:-}" ]; then echo "Skipping Gradle build"; exit 0; fi

# 5. Build the APK
cd android
chmod +x gradlew
./gradlew assembleRelease --no-daemon
