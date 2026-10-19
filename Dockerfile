# Stage 1: Build the Java application
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn -B clean package

# Stage 2: Minimal Java runtime
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create a non-root user
RUN groupadd --system app && useradd --system --gid app --home-dir /app app

COPY --from=build --chown=app:app /app/target/java-devops-app-1.0.0.jar app.jar

# Run as non-root
USER app

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
