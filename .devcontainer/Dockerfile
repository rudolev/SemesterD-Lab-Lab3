FROM alpine:3.20

# Install minimal essentials for a VS Code dev environment
RUN apk update && apk add --no-cache openssh-client git bash gcc nasm make gdb

# Set the default shell to bash
CMD [ "/bin/bash" ]