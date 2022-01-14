FROM ubuntu:18.04 AS bochs-builder

ENV VERSION=2.6.7

# Install bochs dependencies.
RUN apt-get update \
    && apt-get --no-install-recommends -y install \
        curl \
        gcc \
        g++ \
        libc6-dev \
        libncurses-dev \
        libx11-dev \
        libxrandr-dev \
        make \
    && rm -rf /var/lib/apt/lists/*

# Install bochs.
RUN curl -Lo bochs-"$VERSION".tar.gz http://downloads.sourceforge.net/project/bochs/bochs/"$VERSION"/bochs-"$VERSION".tar.gz \
    && tar -xzf bochs-"$VERSION".tar.gz \
    && mv bochs-"$VERSION" bochs \
    && cd bochs \
    && ./configure --build="$(arch)"-unknown-linux-gnu --enable-gdb-stub --with-x --with-x11 --with-term --with-nogui \
    && make -j \
    && make install

FROM ubuntu:18.04

# Install packages.
ENV DEBIAN_FRONTEND=noninteractive
RUN printf 'y\nY\n' | unminimize \
    && rm -rf /var/lib/apt/lists/*
RUN if [ "$(arch)" != 'x86_64' ]; then \
        dpkg --add-architecture amd64 \
        && sed -Ei "s/deb http/deb [arch=$(dpkg --print-architecture)] http/" /etc/apt/sources.list \
        && . /etc/os-release \
        && printf "\n\
deb [arch=amd64] http://archive.ubuntu.com/ubuntu $VERSION_CODENAME main restricted universe multiverse\n\
deb [arch=amd64] http://archive.ubuntu.com/ubuntu $VERSION_CODENAME-updates main restricted universe multiverse\n\
deb [arch=amd64] http://archive.ubuntu.com/ubuntu $VERSION_CODENAME-security main restricted universe multiverse\n\
deb [arch=amd64] http://archive.ubuntu.com/ubuntu $VERSION_CODENAME-backports main restricted universe multiverse\n" \
            >> /etc/apt/sources.list \
    ; fi \
    && apt-get update \
    && apt-get --no-install-recommends -y install \
        ack-grep \
        cgdb \
        clang \
        clang-format \
        cmake \
        exuberant-ctags \
        git \
        glibc-doc \
        golang \
        jupyter \
        less \
        libc6-dev \
        libncurses5 \
        libx11-6 \
        libxrandr2 \
        make \
        man-db \
        openssh-server \
        python3 \
        python3-matplotlib \
        python3-numpy \
        qemu-system-x86 \
        qemu-user \
        qemu-user-binfmt \
        samba \
        silversearcher-ag \
        sudo \
        systemd \
        tmux \
        valgrind \
        vim \
        wget \
        $(if [ "$(arch)" = 'x86_64' ]; then echo \
            gcc-multilib \
            gdb \
        ; else echo \
            gcc-multilib-x86-64-linux-gnu \
            gdb-multiarch \
            libc6:amd64 \
            libc6-i386:amd64 \
        ; fi) \
    && rm -rf /var/lib/apt/lists/*

# Copy bochs from builder.
COPY --from=bochs-builder /bochs /bochs
RUN cd /bochs && make install

# Add a couple files to /usr/local/bin to mimic the functionality of a native
# x86_64 toolchain:
#
# - Link gdb-multiarch to gdb.
# - Link x86_64-linux-gnu-* binutils to binutils.
# - Link to or add wrappers for x86_64-linux-gnu-* to i386-elf-* .
# - Add wrapper to clang to use clang with x86_64 target.
# - Update cc alternative to point to x86_64 compilers.
RUN if [ "$(arch)" != 'x86_64' ]; then \
        ln -s /usr/bin/gdb-multiarch /usr/local/bin/gdb \
        && for f in /usr/bin/x86_64-linux-gnu-*; do \
            basename=$(basename "$f") \
            && name=${basename#x86_64-linux-gnu-} \
            && ln -s "$f" /usr/local/bin/"$name" \
            && case "$name" in \
                gcc) \
                    printf "#!/bin/sh\n\nexec \"$f\" -m32 \"\$@\"\n" > /usr/local/bin/i386-elf-"$name" \
                    && chmod +x /usr/local/bin/i386-elf-"$name" \
                ;; \
                ld) \
                    printf "#!/bin/sh\n\nexec \"$f\" -melf_i386 \"\$@\"\n" > /usr/local/bin/i386-elf-"$name" \
                    && chmod +x /usr/local/bin/i386-elf-"$name" \
                ;; \
                *) \
                    ln -s "$f" /usr/local/bin/i386-elf-"$name" \
                ;; \
            esac \
        ; done \
        && printf "#!/bin/sh\n\nexec /usr/bin/clang -target x86_64 \"\$@\"" >> /usr/local/bin/clang \
        && chmod +x /usr/local/bin/clang \
        && update-alternatives --install /usr/bin/cc cc /usr/bin/x86_64-linux-gnu-gcc 0 \
        && update-alternatives --set cc /usr/bin/x86_64-linux-gnu-gcc \
    ; fi

# Add vagrant user.
RUN useradd --create-home --shell /bin/bash vagrant \
    && printf 'vagrant:vagrant' | chpasswd \
    && printf 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && printf '\n. ~/.cs162.bashrc' >> ~vagrant/.bashrc \
    && printf 'vagrant\nvagrant\n' | smbpasswd -a vagrant

# Install fzf.
RUN cd ~vagrant \
    && su vagrant -c 'git clone --branch 0.25.0 --depth 1 https://github.com/junegunn/fzf.git .fzf' \
    && cd .fzf \
    && su vagrant -c './install --key-bindings --no-completion --update-rc'

# Clone required repos.
RUN cd ~vagrant \
    && sudo -u vagrant mkdir code \
    && su vagrant -c 'git clone --origin staff https://github.com/Berkeley-CS162/student0.git code/student' \
    && su vagrant -c 'git clone --origin staff https://github.com/Berkeley-CS162/group0.git code/group'

# Setup/add configs.
COPY etc /etc/

# Add user resources.
COPY --chown=vagrant:vagrant user /home/vagrant/

EXPOSE 22/tcp
EXPOSE 80/tcp
EXPOSE 139/tcp
EXPOSE 445/tcp
EXPOSE 8080/tcp

CMD ["/lib/systemd/systemd"]
