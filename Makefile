ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ClownFeature

ClownFeature_FILES = DKClownStore.m DKClownEditor.m DKClownHooks.m
ClownFeature_CFLAGS = -fobjc-arc
ClownFeature_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
