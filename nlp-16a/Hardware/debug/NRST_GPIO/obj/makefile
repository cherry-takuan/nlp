################################################################################
# MRS Version: {"version":"1.8.5","date":"2023/05/22"}
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include User/subdir.mk
-include Startup/subdir.mk
-include Peripheral/src/subdir.mk
-include Debug/subdir.mk
-include Core/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(ASM_UPPER_DEPS)),)
-include $(ASM_UPPER_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_DEPS)),)
-include $(S_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
NRST_GPIO.hex \

SECONDARY_LIST += \
NRST_GPIO.lst \

SECONDARY_SIZE += \
NRST_GPIO.siz \


# All Target
all: NRST_GPIO.elf secondary-outputs

# Tool invocations
NRST_GPIO.elf: $(OBJS) $(USER_OBJS)
	@	@	riscv-none-embed-gcc -march=rv32ecxw -mabi=ilp32e -msmall-data-limit=0 -msave-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common -Wunused -Wuninitialized  -g -T "C:\MounRiver\MounRiver_Studio\workspace\NRST_GPIO\Ld\Link.ld" -nostartfiles -Xlinker --gc-sections -Wl,-Map,"NRST_GPIO.map" --specs=nano.specs --specs=nosys.specs -o "NRST_GPIO.elf" $(OBJS) $(USER_OBJS) $(LIBS) -lprintf
	@	@
NRST_GPIO.hex: NRST_GPIO.elf
	@	riscv-none-embed-objcopy -O ihex "NRST_GPIO.elf"  "NRST_GPIO.hex"
	@	@
NRST_GPIO.lst: NRST_GPIO.elf
	@	riscv-none-embed-objdump --all-headers --demangle --disassemble -M xw "NRST_GPIO.elf" > "NRST_GPIO.lst"
	@	@
NRST_GPIO.siz: NRST_GPIO.elf
	@	riscv-none-embed-size --format=berkeley "NRST_GPIO.elf"
	@	@
# Other Targets
clean:
	-$(RM) $(ASM_UPPER_DEPS)$(OBJS)$(SECONDARY_FLASH)$(SECONDARY_LIST)$(SECONDARY_SIZE)$(ASM_DEPS)$(S_DEPS)$(S_UPPER_DEPS)$(C_DEPS) NRST_GPIO.elf
	-@
secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_LIST) $(SECONDARY_SIZE)

.PHONY: all clean dependents

-include ../makefile.targets
