#include <stdio.h>

__attribute__((constructor))
static void libnl_init() {
#ifdef INCLUDE_LOGS
    fprintf(stderr, "[libnl_stub] loaded\n");
#endif
}

void* nl_socket_alloc() {
#ifdef INCLUDE_LOGS
    fprintf(stderr, "[libnl_stub] nl_socket_alloc called\n");
#endif
    return NULL;
}

void nl_socket_free(void* sk) { 
    (void)sk;
#ifdef INCLUDE_LOGS
    fprintf(stderr, "[libnl_stub] nl_socket_free called\n");
#endif
}

int nl_connect(void* sk, int protocol) { 
    (void)sk; 
    (void)protocol; 
#ifdef INCLUDE_LOGS
    fprintf(stderr, "[libnl_stub] nl_connect called\n");
#endif
    return -1;
}

int nl_close(void* sk) { 
    (void)sk; 
#ifdef INCLUDE_LOGS
    fprintf(stderr, "[libnl_stub] nl_close called\n");
#endif
    return 0;
}

int nl_socket_get_fd(void* sk) { 
    (void)sk;
#ifdef INCLUDE_LOGS
    fprintf(stderr, "[libnl_stub] nl_socket_get_fd called\n");
#endif
    return -1;
}