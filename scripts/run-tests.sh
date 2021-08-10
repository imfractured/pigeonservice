#Runs Unit Tests
set -o pipefail && xcodebuild build -project Pigeon.xcodeproj/ \
        -sdk iphonesimulator -scheme Pigeon-Package \
        -destination 'platform=iOS Simulator,name=iPhone 11 Pro' test | xcpretty
