FROM ubuntu:xenial
 
RUN apt update && apt install -y --no-install-recommends \
        ca-certificates \
        curl \
        vim \
        wget \
        byobu \
        git \
        bash-completion \
        software-properties-common \
        postgresql-client \
        openjdk-8-jdk \
#       openjdk-8-jre-dcevm \
        tomcat8 \
        ant \
        maven \
        unzip

WORKDIR /tmp
#Since DCEVM for Xenial seems kind of broken, we download it from zetzy
RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/o/openjdk-8-jre-dcevm/openjdk-8-jre-dcevm_8u112-1_amd64.deb && \
    dpkg -i openjdk-8-jre-dcevm_8u112-1_amd64.deb

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN mkdir -p /srv/dspace /srv/dspace-src

RUN mkdir /root/.m2
#VOLUME /root/.m2


###
# Bash configuration
###

#Configure colors and autocompletion
COPY bashrc /root/.bashrc
COPY bashrc /home/developer/.bashrc

#Configure some useful aliases
COPY bash_aliases /root/.bash_aliases
COPY bash_aliases /home/developer/.bash_aliases

ENV CATALINA_HOME=/usr/share/tomcat8 DSPACE_HOME=/srv/dspace 
ENV PATH=$DSPACE_HOME/bin:$PATH 
###
# Tomcat configuration tweaks
###

# Configure remote debugging and extra memory
COPY setenv.sh $CATALINA_HOME/bin


#Install DCEVM
#COPY libjvm.so /usr/lib/jvm/java-7-oracle/jre/lib/amd64/dcevm/libjvm.so
RUN curl -fSL https://github.com/dcevm/dcevm/releases/download/full-jdk7u79%2B8/DCEVM-full-7u79-installer.jar -o DCEVM-full-7u79-installer.jar
RUN unzip DCEVM-full-7u79-installer.jar
RUN mkdir -p /usr/lib/jvm/java-7-oracle/jre/lib/amd64/dcevm/
RUN ls -l
RUN mv linux_amd64_compiler2/product/libjvm.so /usr/lib/jvm/java-7-oracle/jre/lib/amd64/dcevm/libjvm.so


#Install Hotswap agent
#COPY HotswapAgent-0.3.zip /usr/lib/hotswapagent/HotswapAgent-0.3.zip
ADD https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-0.3/HotswapAgent-0.3.zip HotswapAgent-0.3.zip
RUN mkdir /usr/lib/hotswapagent
RUN unzip HotswapAgent-0.3.zip -d /usr/lib/hotswapagent/
RUN rm HotswapAgent-0.3.zip

RUN apt install -y sudo

RUN export HOME=/home/developer
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

RUN chown -R developer $CATALINA_HOME

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]

#Install PSI Probe
RUN curl -fSL https://github.com/psi-probe/psi-probe/releases/download/2.4.0/probe-2.4.0.zip -o probe.zip
RUN unzip probe.zip
# RUN mv probe.war $CATALINA_HOME/webapps/probe.war

COPY conf $CATALINA_HOME/conf

RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo bash - \
  && apt-get install nodejs -y 

RUN npm install -g grunt bower

###
# Installing an IDE
###

#Download the IDE
#ADD https://download.jetbrains.com/idea/ideaIC-2016.1.2.tar.gz /home/developer/idea

#Required for running Idea IDE
RUN apt-get install libxext-dev libxrender-dev libxtst-dev -y

#To make intellij work. For some reason, it requires the fonts to be installed
RUN  apt-get install fontconfig fontconfig-config fonts-dejavu-core fonts-dejavu-extra -y

###
# Cleanup
###
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/oracle-jdk7-installer
RUN ln -s /srv/dspace/bin/dspace /usr/bin/dspace

#Uncomment this lines to set a custom UID. E.g.: 1009
#RUN export uid=1009 && usermod -u $uid developer
#RUN  chown -R developer:developer /home/developer

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

#Also, give developer ownership of CATALINA_HOME
RUN chown -R developer:developer $CATALINA_HOME/
USER developer

USER developer

RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - \ 
  && curl -sSL https://get.rvm.io | bash -s stable --ruby

RUN bash -c "source ~/.profile \
  && gem install sass -v 3.3.14  \
  && gem install compass -v 1.0.1"

RUN echo "source ~/.profile" >> ~/.bashrc


WORKDIR /srv/dspace-src

EXPOSE 1043:1043
EXPOSE 8080:8080
EXPOSE 8000:8000
