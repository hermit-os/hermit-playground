//! Usage example:
//! Run with `-nic user,hostfwd=::12345-:12345,model=rtl8139` in QEMU
//! Query with `wget -qO- 127.0.0.1:12345`

#include <inttypes.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <unistd.h>
#include <string.h>

int main() {
    const int sfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sfd < 0) {
        puts("socket creation failed");
        exit(1);
    }

    const struct sockaddr_in server_addr = {.sin_family = AF_INET,
                                            .sin_addr.s_addr =
                                                htonl(INADDR_ANY),
                                            .sin_port = htons(12345)};
    if (bind(sfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        puts("bind failed");
        exit(1);
    }

    if (listen(sfd, 64) < 0) {
        puts("listen failed");
        exit(1);
    }

    puts("listening for incoming connections");

    for (;;) {
        puts("awaiting connections");
        struct sockaddr_in address;
        socklen_t addr_len = sizeof(address);
        int cfd;
        if ((cfd = accept(sfd, (struct sockaddr *)&address, &addr_len)) < 0) {
            puts("accept failed");
            exit(1);
        }
        printf("new client: %s:%" PRIu16 "\n", inet_ntoa(address.sin_addr),
               address.sin_port);

        const char *msg = "Hello TCP!\n";
        send(cfd, msg, strlen(msg), 0);

        shutdown(cfd, 2);
        close(cfd);
    }
}
