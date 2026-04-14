.PHONY: help apk windows push clean

APK := build/app/outputs/flutter-apk/app-release.apk

help:
	@echo "Targets:"
	@echo "  make apk      - Build release APK"
	@echo "  make windows  - Build Windows release"
	@echo "  make push     - Send APK to phone via LocalSend (PHONE_IP=192.168.x.y, builds if missing)"
	@echo "  make clean    - flutter clean"

apk: $(APK)

$(APK):
	./tool/build.sh apk

windows:
	./tool/build.sh windows

push: $(APK)
	./tool/push-to-phone.sh

clean:
	flutter clean
