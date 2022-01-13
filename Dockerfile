FROM ubuntu:18.04

# Install packages.
ENV DEBIAN_FRONTEND=noninteractive
RUN printf 'y\nY\n' | unminimize \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get --no-install-recommends -y install \
        ack-grep \
        autoconf \
        bochs \
        cgdb \
        clang \
        clang-format \
        cmake \
        exuberant-ctags \
        gcc-multilib \
        gdb \
        git \
        glibc-doc \
        golang \
        jupyter \
        less \
        libc6-dev \
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
    && rm -rf /var/lib/apt/lists/*

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
