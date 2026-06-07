FIREBASE_VERSION = 11.15.0
FIREBASE_ZIP_URL = https://github.com/firebase/firebase-ios-sdk/releases/download/$(FIREBASE_VERSION)/Firebase.zip

ROOT_DIR := $(shell pwd)
SDK_DIR = $(ROOT_DIR)/firebase_sdk
ADDON_DIR = $(ROOT_DIR)/demo/addons/GodotFirebaseiOS
BUILD_DIR = $(ROOT_DIR)/GodotFirebaseiOS/.build

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
	GoogleAppMeasurement.xcframework \
	GoogleAppMeasurementIdentitySupport.xcframework \
	GoogleDataTransport.xcframework \
	GoogleSignIn.xcframework \
	GoogleUtilities.xcframework \
	RecaptchaInterop.xcframework \
	absl.xcframework \
	grpc.xcframework \
	grpcpp.xcframework \
	leveldb.xcframework \
	nanopb.xcframework \
	openssl_grpc.xcframework


.PHONY: all setup setup-sdk setup-project build clean

all: build

setup: setup-sdk setup-project

setup-sdk:
	@if [ ! -d "$(SDK_DIR)" ] || [ ! -d "$(SDK_DIR)/ios-arm64" ]; then \
		echo "→ Downloading Firebase SDK $(FIREBASE_VERSION)..."; \
		rm -rf $(SDK_DIR); \
		mkdir -p $(ROOT_DIR)/tmp_firebase_download; \
		curl -L -o $(ROOT_DIR)/tmp_firebase_download/Firebase.zip $(FIREBASE_ZIP_URL); \
		unzip -oq $(ROOT_DIR)/tmp_firebase_download/Firebase.zip -d $(ROOT_DIR)/tmp_firebase_download/extracted; \
		find $(ROOT_DIR)/tmp_firebase_download/extracted -name "Firebase-*-latest.zip" -exec unzip -oq {} -d $(ROOT_DIR)/tmp_firebase_download/extracted \; ; \
		echo "→ Copying required frameworks to $(SDK_DIR)..."; \
		mkdir -p $(SDK_DIR); \
		for fw in $(FRAMEWORKS); do \
			find $(ROOT_DIR)/tmp_firebase_download/extracted -name "$$fw" -exec cp -R {} $(SDK_DIR)/ \; ; \
		done; \
		echo "→ Flattening framework slices..."; \
		mkdir -p $(SDK_DIR)/ios-arm64; \
		mkdir -p $(SDK_DIR)/ios-arm64_x86_64-simulator; \
		for fw in $(FRAMEWORKS); do \
			fw_name=$$(echo $$fw | sed 's/.xcframework//'); \
			cp -R $(SDK_DIR)/$$fw/ios-arm64/$$fw_name.framework $(SDK_DIR)/ios-arm64/ 2>/dev/null || true; \
			cp -R $(SDK_DIR)/$$fw/ios-arm64_x86_64-simulator/$$fw_name.framework $(SDK_DIR)/ios-arm64_x86_64-simulator/ 2>/dev/null || true; \
		done; \
		echo "→ Cleaning up temporary download files..."; \
		rm -rf $(ROOT_DIR)/tmp_firebase_download; \
		echo "✓ Firebase SDK setup complete."; \
	else \
		echo "✓ Firebase SDK already present at $(SDK_DIR)."; \
	fi

setup-project:
	@echo "→ Generating Xcode project via XcodeGen..."
	@PATH=/usr/local/bin:$$PATH xcodegen generate --spec $(ROOT_DIR)/GodotFirebaseiOS/project.yml --project $(ROOT_DIR)/GodotFirebaseiOS/
	@echo "✓ Xcode project generated."

build: setup-project
	@echo "→ Building GodotFirebaseiOS for iOS Device..."
	@xcodebuild -project $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj \
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
	@xcodebuild -project $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj \
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
	@for fw in $(FRAMEWORKS); do \
		fw_name=$$(echo $$fw | sed 's/.xcframework//'); \
		device_fw="$(SDK_DIR)/$$fw/ios-arm64/$$fw_name.framework"; \
		sim_fw="$(SDK_DIR)/$$fw/ios-arm64_x86_64-simulator/$$fw_name.framework"; \
		if [ -d "$$device_fw" ] && [ -d "$$sim_fw" ]; then \
			xcodebuild -create-xcframework \
				-framework "$$device_fw" \
				-framework "$$sim_fw" \
				-output "$(ADDON_DIR)/frameworks/$$fw" \
				2>/dev/null; \
		else \
			echo "  ⚠ Copying $$fw as-is (missing expected slices)"; \
			cp -R $(SDK_DIR)/$$fw $(ADDON_DIR)/frameworks/; \
		fi; \
	done
	@echo "✓ Build and update complete."

clean:
	@echo "→ Cleaning build files..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(SDK_DIR)
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS.xcframework
	@rm -rf $(ROOT_DIR)/GodotFirebaseiOS/GodotFirebaseiOS.xcodeproj
	@rm -rf $(ADDON_DIR)/frameworks
	@echo "✓ Clean complete."
