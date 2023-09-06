#include <stdio.h>
#include <dlfcn.h>

int main(int argc, char ** argv) {
    char error_msg[1024];
    void * handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
        sprintf(&error_msg[0], "Unable to open '%s'", argv[1]);
        perror(&error_msg[0]);
        return 1;
    }

    // Do Julia initialization
    int (*julia_init)(int argc, char ** argv) = dlsym(handle, "init_julia");
    if (julia_init == NULL) {
        perror("Unable to dlsym 'julia_init()'");
        return 1;
    }
    julia_init(argc - 1, argv + 1);

    // Load our target function
    void (*dump_prefs)() = dlsym(handle, "dump_prefs");
    if (dump_prefs == NULL) {
        perror("Unable to dlysm 'dump_prefs()'");
        return 1;
    }
    dump_prefs();
    return 0;
}
