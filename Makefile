ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ClownFeature

ClownFeature_FILES = DKClownStore.m DKClownEditor.m DKClownHooks.m
ClownFeature_CFLAGS = -fobjc-arc
ClownFeature_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
