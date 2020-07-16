THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.0:10.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Notify

Notify_FILES = Tweak.xm
Notify_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
