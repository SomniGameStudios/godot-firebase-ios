FIREBASE_VERSION = 11.15.0
FIREBASE_ZIP_URL = https://github.com/firebase/firebase-ios-sdk/releases/download/$(FIREBASE_VERSION)/Firebase.zip

ROOT_DIR := $(shell pwd)
SDK_DIR = $(ROOT_DIR)/firebase_sdk
ADDON_DIR = $(ROOT_DIR)/demo/addons/GodotFirebaseiOS
BUILD_DIR = $(ROOT_DIR)/GodotFirebaseiOS/.build

FRAMEWORKS = \
	FirebaseAnalytics.xcframework \
	FirebaseCore.xcframework \
	FirebaseCoreInternal.xcframework \
	FirebaseInstallations.xcframework \
	GoogleAppMeasurement.xcframework \
	GoogleAppMeasurementIdentitySupport.xcframework \
	GoogleDataTransport.xcframework \
	GoogleUtilities.xcframework \
	nanopb.xcframework \
	Promises.xcframework \
	FirebaseAuth.xcframework \
	GTMSessionFetcher.xcframework \
	RecaptchaInterop.xcframework \
	FirebaseFirestore.xcframework \
	abseil.xcframework \
	gRPC-Core.xcframework \
	gRPC-C++.xcframework \
	leveldb.xcframework \
	FirebaseDatabase.xcframework \
	FirebaseRemoteConfig.xcframework \
	FirebaseSharedSwift.xcframework \
	FirebaseMessaging.xcframework \
	GoogleSignIn.xcframework \
	AppAuth.xcframework \
	GTMAppAuth.xcframework

.PHONY: all setup setup-sdk setup-project build clean

all: build

setup: setup-sdk setup-project

setup-sdk:
	@if [ ! -d "$(SDK_DIR)" ]; then \
		echo "→ Downloading Firebase SDK $(FIREBASE_VERSION)..."; \
		mkdir -p $(ROOT_DIR)/tmp_firebase_download; \
		curl -L -o $(ROOT_DIR)/tmp_firebase_download/Firebase.zip $(FIREBASE_ZIP_URL); \
		echo "→ Extracting Firebase SDK..."; \
		unzip -q $(ROOT_DIR)/tmp_firebase_download/Firebase.zip -d $(ROOT_DIR)/tmp_firebase_download/extracted; \
		echo "→ Copying required frameworks to $(SDK_DIR)..."; \
		mkdir -p $(SDK_DIR); \
		for fw in $(FRAMEWORKS); do \
			find $(ROOT_DIR)/tmp_firebase_download/extracted -name "$$fw" -exec cp -R {} $(SDK_DIR)/ \; ; \
		done; \
		echo "→ Cleaning up temporary download files..."; \
		rm -rf $(ROOT_DIR)/tmp_firebase_download; \
		echo "✓ Firebase SDK setup complete."; \
	else \
		echo "✓ Firebase SDK already present at $(SDK_DIR)."; \
	fi

setup-project:
	@echo "→ Generating Xcode project via XcodeGen..."
	@xcodegen generate --spec $(ROOT_DIR)/GodotFirebaseiOS/project.yml --project $(ROOT_DIR)/GodotFirebaseiOS/
	@echo "✓ Xcode project generated."

build: setup-project
	@echo "→ Building GodotFirebaseiOS for iOS Device..."
	@xcodebuild -project $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj \
		-scheme GodotFirebaseiOS \
		-sdk iphoneos \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/xcodebuild \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		| tail -20
	@echo "→ Building GodotFirebaseiOS for iOS Simulator..."
	@xcodebuild -project $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj \
		-scheme GodotFirebaseiOS \
		-sdk iphonesimulator \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR)/xcodebuild \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		| tail -20
	@echo "→ Creating universal XCFramework..."
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@xcodebuild -create-xcframework \
		-framework $(BUILD_DIR)/xcodebuild/Build/Products/Release-iphoneos/GodotFirebaseiOS.framework \
		-framework $(BUILD_DIR)/xcodebuild/Build/Products/Release-iphonesimulator/GodotFirebaseiOS.framework \
		-output $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@echo "→ Copying frameworks to addon directory..."
	@rm -rf $(ADDON_DIR)/GodotFirebaseiOS.xcframework
	@cp -R $(ROOT_DIR)/GodotFirebaseiOS.xcframework $(ADDON_DIR)/
	@for fw in $(FRAMEWORKS); do \
		rm -rf $(ADDON_DIR)/$$fw; \
		cp -R $(SDK_DIR)/$$fw $(ADDON_DIR)/; \
	done
	@echo "✓ Build and update complete."

clean:
	@echo "→ Cleaning build files..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(SDK_DIR)
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj
	@for fw in $(FRAMEWORKS); do \
		rm -rf $(ADDON_DIR)/$$fw; \
	done
	@rm -rf $(ADDON_DIR)/GodotFirebaseiOS.xcframework
	@echo "✓ Clean complete."
