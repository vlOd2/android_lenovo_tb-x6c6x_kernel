#include <stdio.h>

__attribute__((constructor))
static void libnl_init(void) {
    fprintf(stderr, "[libnl_stub] loaded\n");
}

void *nl_socket_alloc(void) { return NULL; }
void nl_socket_free(void *sk) { (void)sk; }
int nl_connect(void *sk, int protocol) { (void)sk; (void)protocol; return -1; }
int nl_close(void *sk) { (void)sk; return 0; }
int nl_socket_get_fd(void *sk) { (void)sk; return -1; }