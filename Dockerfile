FROM openjdk:11-jdk-slim as builder
WORKDIR app
COPY mvnw ./
COPY .mvn .mvn
COPY pom.xml ./
COPY src/ ./src
RUN chmod +x ./mvnw
RUN ./mvnw clean install
RUN mv ./target/*jar ./target/app.jar


FROM openjdk:11-jre
ENV DOCKERIZE_VERSION=v0.7.0
RUN apt-get update \
    && apt-get install -y wget \
    && wget -O - https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar xzf - -C /usr/local/bin \
    && apt-get autoremove -yqq --purge wget && rm -rf /var/lib/apt/lists/*
COPY --from=builder app/target/app.jar ./
ENTRYPOINT ["java","-jar","/app.jar"]
