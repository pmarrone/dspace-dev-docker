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
 
#RUN sed -i s/CONFIDENTIAL/NONE/ /usr/local/tomcat/webapps/rest/WEB-INF/web.xml
 
#Install DCEVM
COPY libjvm.so /usr/lib/jvm/java-7-oracle/jre/lib/amd64/server/dcevm/libjvm.so
RUN mkdir /usr/lib/hotswapagent

#Install Hotswap agent
COPY HotswapAgent-0.3.zip /usr/lib/hotswapagent/HotswapAgent-0.3.zip

RUN ln -s /tmp/maven/bin/mvn /usr/bin/mvn 

# # Install root filesystem
# ADD ./rootfs /
 
RUN mkdir -p /srv/dspace /srv/dspace-src

RUN apt-get install bash-completion

RUN mkdir /root/.m2
#VOLUME /root/.m2

RUN apt-get install git -y
RUN apt-get install byobu -y

COPY bashrc /root/.bashrc
COPY bash_aliases /root/.bash_aliases
COPY setenv.sh $CATALINA_HOME/bin

RUN ln -s /u

RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/oracle-jdk7-installer
RUN ln -s /srv/dspace/bin/dspace /usr/bin/dspace

WORKDIR /srv/dspace-src