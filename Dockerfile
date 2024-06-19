FROM openjdk:11-jdk-slim
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} *.jar
ENTRYPOINT ["java","-jar","/*.jar"]
