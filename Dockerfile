FROM ubuntu:18.04
RUN printf 'y\nY\n' | unminimize
ADD modules /puppet/modules
ADD manifests /puppet/manifests
RUN apt -y update
RUN apt -y install puppet
RUN useradd --create-home --home-dir /home/vagrant --user-group vagrant --shell /bin/bash
RUN echo vagrant:vagrant | chpasswd
RUN echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN puppet apply /puppet/manifests/site.pp --modulepath /puppet/modules
EXPOSE 16222:22
EXPOSE 16280:80
CMD ["/lib/systemd/systemd"]
