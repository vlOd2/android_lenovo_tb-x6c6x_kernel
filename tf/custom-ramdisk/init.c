// Syscall numbers for ARM64
#define SYS_WRITE 64
#define SYS_EXIT  93
#define STDOUT    1

long strlen(const char* s) {
    const char* p = s;
    while (*p) {
		p++;
	}
    return (long)(p - s);
}

void print(const char* str) {
    long len = strlen(str);
    
    __asm__ volatile (
        "svc #0"
        : // No output
        : "r" (SYS_WRITE), "r" (STDOUT), "r" (str), "r" (len)
        : "x0", "x1", "x2", "x8", "memory"
    );
}

void _start() {
	while (1) {
        print("Hello, ARM64 without stdlib!\n");
    }
}