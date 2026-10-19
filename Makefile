# Theos Makefile —— 独立小丑模块
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:12.0

TWEAK_NAME = ClownFeature
ClownFeature_FILES = ClownFeature/DKClownStore.m ClownFeature/DKClownEditor.m ClownFeature/DKClownHooks.m
ClownFeature_FRAMEWORKS = UIKit Foundation
ClownFeature_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
