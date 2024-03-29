# dexpreopt_odex_install.mk is used to define odex creation rules for JARs and APKs
# This file depends on variables set in base_rules.mk
# Output variables: LOCAL_DEX_PREOPT, built_odex, dexpreopt_boot_jar_module

# Setting LOCAL_DEX_PREOPT based on WITH_DEXPREOPT, LOCAL_DEX_PREOPT, etc
LOCAL_DEX_PREOPT := $(strip $(LOCAL_DEX_PREOPT))
ifneq (true,$(WITH_DEXPREOPT))
  LOCAL_DEX_PREOPT :=
else # WITH_DEXPREOPT=true
  ifeq (,$(TARGET_BUILD_APPS)) # TARGET_BUILD_APPS empty
    ifndef LOCAL_DEX_PREOPT # LOCAL_DEX_PREOPT undefined
      ifeq (,$(LOCAL_APK_LIBRARIES)) # LOCAL_APK_LIBRARIES empty
        LOCAL_DEX_PREOPT := $(DEX_PREOPT_DEFAULT)
      else # LOCAL_APK_LIBRARIES not empty
        LOCAL_DEX_PREOPT := nostripping
      endif # LOCAL_APK_LIBRARIES not empty
    endif # LOCAL_DEX_PREOPT undefined
  endif # TARGET_BUILD_APPS empty
endif # WITH_DEXPREOPT=true
ifeq (false,$(LOCAL_DEX_PREOPT))
  LOCAL_DEX_PREOPT :=
endif
ifdef LOCAL_UNINSTALLABLE_MODULE
LOCAL_DEX_PREOPT :=
endif
ifeq (,$(strip $(all_java_sources)$(full_static_java_libs)$(my_prebuilt_src_file))) # contains no java code
LOCAL_DEX_PREOPT :=
endif
# if module oat file requested in data, disable LOCAL_DEX_PREOPT, will default location to dalvik-cache
ifneq (,$(filter $(LOCAL_MODULE),$(PRODUCT_DEX_PREOPT_PACKAGES_IN_DATA)))
LOCAL_DEX_PREOPT :=
endif

built_odex :=
installed_odex :=
built_installed_odex :=
ifdef LOCAL_DEX_PREOPT
dexpreopt_boot_jar_module := $(filter $(DEXPREOPT_BOOT_JARS_MODULES),$(LOCAL_MODULE))
ifdef dexpreopt_boot_jar_module
ifeq ($(DALVIK_VM_LIB),libdvm.so)
built_odex := $(basename $(LOCAL_BUILT_MODULE)).odex
installed_odex := $(basename $(LOCAL_INSTALLED_MODULE)).odex
built_installed_odex := $(built_odex):$(installed_odex)
else # libdvm.so
# For libart, the boot jars' odex files are replaced by $(DEFAULT_DEX_PREOPT_INSTALLED_IMAGE).
# We use this installed_odex trick to get boot.art installed.
installed_odex := $(DEFAULT_DEX_PREOPT_INSTALLED_IMAGE)
# Append the odex for the 2nd arch if we have one.
installed_odex += $($(TARGET_2ND_ARCH_VAR_PREFIX)DEFAULT_DEX_PREOPT_INSTALLED_IMAGE)
endif # libdvm.so
else  # boot jar
ifeq ($(DALVIK_VM_LIB),libdvm.so)
built_odex := $(basename $(LOCAL_BUILT_MODULE)).odex
installed_odex := $(basename $(LOCAL_INSTALLED_MODULE)).odex
built_installed_odex := $(built_odex):$(installed_odex)

$(built_odex) : $(DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT) \
                $(DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS)
else # libart
ifeq ($(LOCAL_MODULE_CLASS),JAVA_LIBRARIES)
# For a Java library, we build odex for both 1st arch and 2nd arch, if we have one.
# #################################################
# Odex for the 1st arch
built_odex := $(call get-odex-file-path,$(DEX2OAT_TARGET_ARCH),$(LOCAL_BUILT_MODULE))
ifdef LOCAL_DEX_PREOPT_IMAGE_LOCATION
my_dex_preopt_image_location := $(LOCAL_DEX_PREOPT_IMAGE_LOCATION)
else
my_dex_preopt_image_location := $(DEFAULT_DEX_PREOPT_BUILT_IMAGE_LOCATION)
endif
my_dex_preopt_image_filename := $(call get-image-file-path,$(DEX2OAT_TARGET_ARCH),$(my_dex_preopt_image_location))
$(built_odex): PRIVATE_2ND_ARCH_VAR_PREFIX :=
$(built_odex): PRIVATE_DEX_LOCATION := $(patsubst $(PRODUCT_OUT)%,%,$(LOCAL_INSTALLED_MODULE))
$(built_odex): PRIVATE_DEX_PREOPT_IMAGE_LOCATION := $(my_dex_preopt_image_location)
$(built_odex) : $(DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT) \
                $(DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS) \
                $(my_dex_preopt_image_filename)
installed_odex := $(call get-odex-file-path,$(DEX2OAT_TARGET_ARCH),$(LOCAL_INSTALLED_MODULE))
built_installed_odex := $(built_odex):$(installed_odex)
# #################################################
# Odex for the 2nd arch
ifdef TARGET_2ND_ARCH
built_odex2 := $(call get-odex-file-path,$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH),$(LOCAL_BUILT_MODULE))
ifdef LOCAL_DEX_PREOPT_IMAGE_LOCATION
my_dex_preopt_image_location := $(LOCAL_DEX_PREOPT_IMAGE_LOCATION)
else
my_dex_preopt_image_location := $($(TARGET_2ND_ARCH_VAR_PREFIX)DEFAULT_DEX_PREOPT_BUILT_IMAGE_LOCATION)
endif
my_dex_preopt_image_filename := $(call get-image-file-path,$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH),$(my_dex_preopt_image_location))
$(built_odex2): PRIVATE_2ND_ARCH_VAR_PREFIX := $(TARGET_2ND_ARCH_VAR_PREFIX)
$(built_odex2): PRIVATE_DEX_LOCATION := $(patsubst $(PRODUCT_OUT)%,%,$(LOCAL_INSTALLED_MODULE))
$(built_odex2): PRIVATE_DEX_PREOPT_IMAGE_LOCATION := $(my_dex_preopt_image_location)
$(built_odex2) : $($(TARGET_2ND_ARCH_VAR_PREFIX)DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT) \
                 $(DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS) \
                 $(my_dex_preopt_image_filename)

installed_odex2 := $(call get-odex-file-path,$($(TARGET_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH),$(LOCAL_INSTALLED_MODULE))
built_odex += $(built_odex2)
installed_odex += $(installed_odex2)
built_installed_odex += $(built_odex2):$(installed_odex2)
endif  # TARGET_2ND_ARCH
# #################################################
else  # must be APPS
# For an app, we build for the multilib arch it's targeted for.
built_odex := $(call get-odex-file-path,$($(LOCAL_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH),$(LOCAL_BUILT_MODULE))
ifdef LOCAL_DEX_PREOPT_IMAGE_LOCATION
my_dex_preopt_image_location := $(LOCAL_DEX_PREOPT_IMAGE_LOCATION)
else
my_dex_preopt_image_location := $($(LOCAL_2ND_ARCH_VAR_PREFIX)DEFAULT_DEX_PREOPT_BUILT_IMAGE_LOCATION)
endif
my_dex_preopt_image_filename := $(call get-image-file-path,$($(LOCAL_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH),$(my_dex_preopt_image_location))
$(built_odex): PRIVATE_2ND_ARCH_VAR_PREFIX := $(LOCAL_2ND_ARCH_VAR_PREFIX)
$(built_odex): PRIVATE_DEX_LOCATION := $(patsubst $(PRODUCT_OUT)%,%,$(LOCAL_INSTALLED_MODULE))
$(built_odex): PRIVATE_DEX_PREOPT_IMAGE_LOCATION := $(my_dex_preopt_image_location)
$(built_odex) : $($(LOCAL_2ND_ARCH_VAR_PREFIX)DEXPREOPT_ONE_FILE_DEPENDENCY_BUILT_BOOT_PREOPT) \
                $(DEXPREOPT_ONE_FILE_DEPENDENCY_TOOLS) \
                $(my_dex_preopt_image_filename)
installed_odex := $(call get-odex-file-path,$($(LOCAL_2ND_ARCH_VAR_PREFIX)DEX2OAT_TARGET_ARCH),$(LOCAL_INSTALLED_MODULE))
built_installed_odex := $(built_odex):$(installed_odex)
endif  # LOCAL_MODULE_CLASS
endif # libart
endif # boot jar

ifdef built_odex
# Use pattern rule - we may have multiple installed odex files.
# Ugly syntax - See the definition get-odex-file-path.
$(installed_odex) : $(dir $(LOCAL_INSTALLED_MODULE))%$(notdir $(word 1,$(installed_odex))) \
                  : $(dir $(LOCAL_BUILT_MODULE))%$(notdir $(word 1,$(built_odex))) \
    | $(ACP)
	@echo "Install: $@"
	$(copy-file-to-target)
endif

# Add the installed_odex to the list of installed files for this module.
ALL_MODULES.$(my_register_name).INSTALLED += $(installed_odex)
ALL_MODULES.$(my_register_name).BUILT_INSTALLED += $(built_installed_odex)

# Make sure to install the .odex when you run "make <module_name>"
$(my_register_name): $(installed_odex)

endif # LOCAL_DEX_PREOPT
