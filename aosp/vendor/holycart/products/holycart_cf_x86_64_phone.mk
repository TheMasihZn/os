# Cuttlefish x86_64 phone (emulator) + Holy Cart apps.
# Recent AOSP builds the 64-bit-only phone from vsoc_x86_64_only; older trees use vsoc_x86_64.
HOLY_CF_BASE := $(firstword $(wildcard \
    device/google/cuttlefish/vsoc_x86_64_only/phone/aosp_cf.mk \
    device/google/cuttlefish/vsoc_x86_64/phone/aosp_cf.mk))
ifeq ($(HOLY_CF_BASE),)
$(error Cuttlefish x86_64 phone product not found under device/google/cuttlefish)
endif
$(call inherit-product, $(HOLY_CF_BASE))
$(call inherit-product, vendor/holycart/holycart.mk)

PRODUCT_NAME := holycart_cf_x86_64_phone
PRODUCT_BRAND := HolyCart
PRODUCT_MODEL := Holy Cart OS (Cuttlefish x86_64)
PRODUCT_MANUFACTURER := HolyCart
