# Multi-stage Dockerfile for MyBatis JPetStore Application
# Stage 1: Build stage with Maven and JDK 17
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy POM and dependencies first to leverage Docker layer caching
COPY pom.xml .
COPY format.xml .

# Download dependencies
RUN mvn dependency:go-offline -B || true

# Copy source code and build WAR
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Minimal, secure runtime stage with Apache Tomcat 9
FROM tomcat:9.0-jre17-temurin-jammy

LABEL maintainer="Mukesh Chaudhary"
LABEL description="Production-ready container for PetStore Application"
LABEL org.opencontainers.image.source="https://github.com/mukeshchaudhary14/Petstore_App"

# Create dedicated non-root user and group for security (Trivy compliance)
RUN groupadd -r tomcat -g 1001 && \
    useradd -r -u 1001 -g tomcat -d /usr/local/tomcat -s /usr/sbin/nologin tomcat

# Remove default sample web applications for security hardening
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy built WAR artifact from builder stage to both ROOT.war and jpetstore.war
COPY --from=builder /app/target/jpetstore.war /usr/local/tomcat/webapps/ROOT.war
COPY --from=builder /app/target/jpetstore.war /usr/local/tomcat/webapps/jpetstore.war

# Set correct file permissions for non-root user
RUN chown -R tomcat:tomcat /usr/local/tomcat

# Set JVM and Environment options
ENV JPETSTORE_PORT=8080 \
    CATALINA_HOME=/usr/local/tomcat \
    CATALINA_BASE=/usr/local/tomcat \
    JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom"

# Switch to non-root user
USER 1001

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=35s --retries=3 \
  CMD curl -f http://localhost:8080/jpetstore/ || curl -f http://localhost:8080/ || exit 1

# Start Tomcat server
CMD ["catalina.sh", "run"]
