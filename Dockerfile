FROM ubuntu:trusty
 
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget
 
# Environment variables
ENV TOMCAT_MAJOR=8 TOMCAT_VERSION=8.0.33
ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
    MAVEN_TGZ_URL=http://apache.mirror.iweb.ca/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
 
ENV CATALINA_HOME=/usr/local/tomcat DSPACE_HOME=/srv/dspace
ENV PATH=$CATALINA_HOME/bin:$DSPACE_HOME/bin:$PATH
 
WORKDIR /tmp
 
RUN apt-get install software-properties-common -y
 
RUN \
  echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java7-installer
 
# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle
 
# Install runtime and dependencies
RUN apt-get install -y vim ant postgresql-client
 
RUN mkdir -p maven dspace "$CATALINA_HOME"
 
RUN curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz
RUN curl -fSL "$MAVEN_TGZ_URL" -o maven.tar.gz \
    && tar -xvf tomcat.tar.gz --strip-components=1 -C "$CATALINA_HOME" \
    && tar -xvf maven.tar.gz --strip-components=1  -C maven

RUN apt-get install git -y
RUN apt-get install byobu -y

 
#RUN sed -i s/CONFIDENTIAL/NONE/ /usr/local/tomcat/webapps/rest/WEB-INF/web.xml
 
#Install DCEVM
COPY libjvm.so /usr/lib/jvm/java-7-oracle/jre/lib/amd64/dcevm/libjvm.so
COPY libjvm.so /usr/lib/jvm/java-7-oracle/jre/lib/amd64/server/dcevm/libjvm.so
RUN mkdir /usr/lib/hotswapagent

#Install Hotswap agent
COPY HotswapAgent-0.3.zip /usr/lib/hotswapagent/HotswapAgent-0.3.zip

RUN ln -s /tmp/maven/bin/mvn /usr/bin/mvn 
 
RUN mkdir -p /srv/dspace /srv/dspace-src

RUN apt-get install bash-completion

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

###
# Tomcat configuration tweaks
###

# Configure remote debugging and extra memory
COPY setenv.sh $CATALINA_HOME/bin


###
# Installing an IDE
###

#Required for running Idea IDE
RUN apt-get install libxext-dev libxrender-dev libxtst-dev -y

#To make intellij work. For some reason, it requires the fonts to be installed
RUN  apt-get install fontconfig fontconfig-config fonts-dejavu-core fonts-dejavu-extra -y

#Download the IDE
#ADD https://download.jetbrains.com/idea/ideaIC-2016.1.2.tar.gz /home/developer/idea

RUN apt-get install unzip -y
RUN unzip /usr/lib/hotswapagent/HotswapAgent-0.3.zip -d /usr/lib/hotswapagent/
RUN rm /usr/lib/hotswapagent/HotswapAgent-0.3.zip

###
# Cleanup
###
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/oracle-jdk7-installer
RUN ln -s /srv/dspace/bin/dspace /usr/bin/dspace

RUN export HOME=/home/developer
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

RUN chown -R developer $CATALINA_HOME

COPY jdk-7u79-linux-x64.tar.gz /tmp/jdk-7u79-linux-x64.tar.gz
RUN tar -xvzf jdk-7u79-linux-x64.tar.gz --strip-components=1 -C /usr/lib/jvm/java-7-oracle/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]

#Install PSI Probe
COPY probe.war $CATALINA_HOME/webapps/probe.war

COPY conf $CATALINA_HOME/conf

RUN curl -sL https://deb.nodesource.com/setup | sudo bash - \
  && apt-get install nodejs -y 

RUN npm install -g grunt bower

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
