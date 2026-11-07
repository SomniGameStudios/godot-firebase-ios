# Recipes pipe xcodebuild through tail, and make only sees the last command's
# exit status. pipefail makes a failed xcodebuild fail the recipe instead of
# silently packaging the previous build's products. It is set per line below
# because the make that ships with macOS (3.81) silently ignores .SHELLFLAGS.
SHELL := /bin/bash

FIREBASE_VERSION = 12.19.3
FIREBASE_ZIP_URL = https://github.com/firebase/firebase-ios-sdk/releases/download/$(FIREBASE_VERSION)/Firebase.zip

ROOT_DIR := $(shell pwd)
SDK_DIR = $(ROOT_DIR)/firebase_sdk
ADDON_DIR = $(ROOT_DIR)/demo/addons/GodotFirebaseiOS
BUILD_DIR = $(ROOT_DIR)/GodotFirebaseiOS/.build/firebase-$(FIREBASE_VERSION)

FRAMEWORKS = \
	AppAuth.xcframework \
	AppCheckCore.xcframework \
	FBLPromises.xcframework \
	FirebaseABTesting.xcframework \
	FirebaseAnalytics.xcframework \
	FirebaseAppCheckInterop.xcframework \
	FirebaseAuth.xcframework \
	FirebaseAuthInterop.xcframework \
	FirebaseCore.xcframework \
	FirebaseCoreExtension.xcframework \
	FirebaseCoreInternal.xcframework \
	FirebaseDatabase.xcframework \
	FirebaseFirestore.xcframework \
	FirebaseFirestoreInternal.xcframework \
	FirebaseInstallations.xcframework \
	FirebaseMessaging.xcframework \
	FirebaseMessagingInterop.xcframework \
	FirebaseRemoteConfig.xcframework \
	FirebaseRemoteConfigInterop.xcframework \
	FirebaseSharedSwift.xcframework \
	GTMAppAuth.xcframework \
	GTMSessionFetcher.xcframework \
	GoogleAdsOnDeviceConversion.xcframework \
	GoogleAppMeasurement.xcframework \
	GoogleAppMeasurementIdentitySupport.xcframework \
	GoogleDataTransport.xcframework \
	GoogleSignIn.xcframework \
	GoogleUtilities.xcframework \
	Promises.xcframework \
	RecaptchaInterop.xcframework \
	absl.xcframework \
	grpc.xcframework \
	grpcpp.xcframework \
	leveldb.xcframework \
	nanopb.xcframework \
	openssl_grpc.xcframework


.PHONY: all setup setup-sdk setup-project build clean test test-link

all: build

setup: setup-sdk setup-project

setup-sdk:
	@python3 scripts/setup_firebase_sdk.py "$(FIREBASE_VERSION)" "$(FIREBASE_ZIP_URL)" "$(SDK_DIR)" $(FRAMEWORKS)

setup-project:
	@echo "→ Generating Xcode project via XcodeGen..."
	@PATH=/usr/local/bin:$$PATH xcodegen generate --spec $(ROOT_DIR)/GodotFirebaseiOS/project.yml --project $(ROOT_DIR)/GodotFirebaseiOS/
	@echo "✓ Xcode project generated."

build: setup-sdk setup-project
	@echo "→ Building GodotFirebaseiOS for iOS Device..."
	@set -o pipefail; xcodebuild -project $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj \
		-scheme GodotFirebaseiOS \
		-destination "generic/platform=iOS" \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/xcodebuild \
		-skipPackagePluginValidation \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		| tail -20
	@echo "→ Building GodotFirebaseiOS for iOS Simulator..."
	@set -o pipefail; xcodebuild -project $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj \
		-scheme GodotFirebaseiOS \
		-destination "generic/platform=iOS Simulator" \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/xcodebuild \
		-skipPackagePluginValidation \
		-skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		| tail -20
	@echo "→ Copying Firebase bundles into frameworks..."
	@find $(SDK_DIR) -name "*.bundle" -exec cp -R {} $(BUILD_DIR)/xcodebuild/Build/Products/Release-iphoneos/GodotFirebaseiOS.framework/ \;
	@find $(SDK_DIR) -name "*.bundle" -exec cp -R {} $(BUILD_DIR)/xcodebuild/Build/Products/Release-iphonesimulator/GodotFirebaseiOS.framework/ \;
	@echo "→ Creating universal XCFramework..."
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@xcodebuild -create-xcframework \
		-framework $(BUILD_DIR)/xcodebuild/Build/Products/Release-iphoneos/GodotFirebaseiOS.framework \
		-framework $(BUILD_DIR)/xcodebuild/Build/Products/Release-iphonesimulator/GodotFirebaseiOS.framework \
		-output $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@echo "→ Copying frameworks to addon directory..."
	@rm -rf $(ADDON_DIR)/frameworks
	@mkdir -p $(ADDON_DIR)/frameworks
	@touch $(ADDON_DIR)/frameworks/.gdignore
	@cp -R $(ROOT_DIR)/GodotFirebaseiOS.xcframework $(ADDON_DIR)/frameworks/
	@echo "→ Repackaging vendor frameworks (iOS-only)..."
	@set -e; for fw in $(FRAMEWORKS); do \
		fw_name=$$(echo $$fw | sed 's/.xcframework//'); \
		device_fw="$(SDK_DIR)/$$fw/ios-arm64/$$fw_name.framework"; \
		sim_fw="$(SDK_DIR)/$$fw/ios-arm64_x86_64-simulator/$$fw_name.framework"; \
		if [ -d "$$device_fw" ] && [ -d "$$sim_fw" ]; then \
			xcodebuild -create-xcframework \
				-framework "$$device_fw" \
				-framework "$$sim_fw" \
				-output "$(ADDON_DIR)/frameworks/$$fw"; \
		else \
			echo "  ⚠ Copying $$fw as-is (missing expected slices)"; \
			cp -R $(SDK_DIR)/$$fw $(ADDON_DIR)/frameworks/; \
		fi; \
	done
	@echo "✓ Build and update complete."

clean:
	@echo "→ Cleaning build files..."
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS/.build
	@rm -rf $(SDK_DIR)
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj
	@[ -d $(ADDON_DIR)/frameworks ] && find $(ADDON_DIR)/frameworks -mindepth 1 ! -name ".gdignore" -exec rm -rf {} + || true
	@echo "✓ Clean complete."

test:
	@python3 -m unittest discover -s tests -v

# Force-load vendor archives as the Godot export does, without Firebase credentials.
test-link: setup-sdk
	@python3 scripts/test_firebase_link.py "$(SDK_DIR)" $(FRAMEWORKS)
