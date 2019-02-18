AR = xtensa-lx106-elf-ar
CC = xtensa-lx106-elf-gcc
NM = xtensa-lx106-elf-nm
CPP = xtensa-lx106-elf-g++
LD = xtensa-lx106-elf-gcc
OBJCOPY = xtensa-lx106-elf-objcopy
OBJDUMP = xtensa-lx106-elf-objdump

CFLAGS +=                   \
    -Os                     \
    -g                      \
    -Wpointer-arith         \
    -Wundef                 \
    -Werror                 \
    -Wl,-EL                 \
    -fno-inline-functions   \
    -nostdlib               \
    -mlongcalls             \
    -mtext-section-literals \
    -D__ets__               \
    -DICACHE_FLASH         

CCFLAGS +=                  \
    -Os                     \
    -g                      \
    -Wpointer-arith         \
    -Wundef                 \
    -Werror                 \
    -Wl,-EL                 \
    -fno-inline-functions   \
    -nostdlib               \
    -mlongcalls             \
    -mtext-section-literals \
    -D__ets__               \
    -DICACHE_FLASH          \
    -fno-rtti               \
    -fno-exceptions
   
INCLUDES +=                 \
    -I./dep/inc             \
    -I./src               

LDDIR = -L./dep/ld

LDFILE = -Teagle.app.v6.ld

# LIBS =-L./dep/lib -lc -lmain -lgcc -lssl -lhal -lphy -lpp -lnet80211 -llwip -lwpa -lwpa2 -lupgrade -lpwm -lsmartconfig -lwps -lcrypto -luart -lssl
LIBS =-L./dep/lib -lc -lmain -lgcc -lssl -lphy -lpp -lnet80211 -llwip -lwpa -lwpa2 -lupgrade -lpwm -lsmartconfig -lwps -lcrypto -lssl
    


SRC = $(wildcard ./src/*.cpp)
SRCC = $(wildcard ./src/*.c)
OBJ = $(SRC:.cpp=.cpp.o)
OBJC = $(SRCC:.c=.o)

LDFLAGS +=                  \
    -nostdlib               \
    -Wl,--no-check-sections \
    -u call_user_start      \
    -Wl,-static             \
    $(LDDIR)                \
    $(LDFILE)               \
    -Wl,--start-group       \
    $(LIBS)                 \
    app.a                   \
    -Wl,--end-group   

all: fichero.app.out
	$(OBJDUMP) --headers --section=.data --section=.rodata --section=.bss --section=.text --section=.irom0.text fichero.app.out
	$(OBJCOPY) --only-section .text --output-target binary fichero.app.out eagle.app.v6.text.bin
	$(OBJCOPY) --only-section .data --output-target binary fichero.app.out eagle.app.v6.data.bin
	$(OBJCOPY) --only-section .rodata --output-target binary fichero.app.out eagle.app.v6.rodata.bin
	$(OBJCOPY) --only-section .irom0.text --output-target binary fichero.app.out eagle.app.v6.irom0text.bin
	C:\Python27\python.exe ./dep/tool/gen_appbin.py fichero.app.out 0 0 0 0 6


fichero.app.out: app.a
	$(LD) $(LDFLAGS) -o $@ $^

app.a: $(OBJ) $(OBJC)
	$(AR) -cru app.a $^

$(OBJ): $(SRC)
	$(CPP) $(CCFLAGS) $(INCLUDES) -c $(@:.o=) -o $@
   
$(OBJC): $(SRCC)
	$(CC) $(CFLAGS) $(INCLUDES) -c $(@:.o=.c) -o $@
   
clean:
	rm app.a $(OBJ) $(OBJC) eagle.app.sym
	rm eagle.app.v6.data.bin eagle.app.v6.irom0text.bin
	rm eagle.app.v6.rodata.bin eagle.app.v6.text.bin fichero.app.out
	rm eagle.app.flash.bin

flash:
	esptool -p COM3 -b 115200 write_flash --flash_freq 40m --flash_mode qio --flash_size 4MB 0x00000 eagle.app.flash.bin 0x10000 eagle.app.v6.irom0text.bin 0x3FC000 ./dep/tool/esp_init_data_default.bin  0x3FE000 ./dep/tool/blank.bin