TARGET_CODESIGN = $(shell which ldid)

APP_TMP         	= $(TMPDIR)/iMemScan-build
APP_BUNDLE_PATH 	= $(APP_TMP)/Build/Products/Release-iphoneos/TrollMemScan.app

all:
	xcodebuild -quiet -jobs $(shell sysctl -n hw.ncpu) -project 'iMemScan.xcodeproj' -scheme iMemScan -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(APP_TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(APP_TMP)/install
		
	ldid -S$(CURDIR)/entitlements.plist $(APP_BUNDLE_PATH)/TrollMemScan
	rm -rf build
	mkdir -p build/Payload

	mv $(APP_BUNDLE_PATH) 	build/Payload

	# make TrollStore tipa
	@ln -sf build/Payload Payload
	zip -r9 iMemScanTS.tipa Payload
	@rm -rf Payload

	# Clean up build temp
	find . -name ".DS_Store" -delete
	@rm -rf build/Payload

	@echo TrollStore .tipa written successfully as iMemScanTS.tipa
