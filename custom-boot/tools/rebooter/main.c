#include <stdio.h>
#include <unistd.h>
#include <sys/reboot.h>
#include <sys/syscall.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
		printf("error: a reboot reason is required\n");
		return 1;	
	}

    // 0xa1b2c3d4 maps to LINUX_REBOOT_CMD_RESTART2
    syscall(SYS_reboot, 0xfee1dead, 672274793, 0xa1b2c3d4, argv[1]);
    
    return 0;
}