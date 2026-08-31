# Build stage
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app

# Copy Maven files first for dependency caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application
RUN mvn clean package -DskipTests -B

# Runtime stage - Tomcat 9.x, matching this app's javax.servlet (Java EE) API
# NOTE: do NOT use Tomcat 10+, which requires jakarta.servlet and will fail
# to load this app's HttpServlet classes (ClassNotFoundException at deploy)
FROM tomcat:9.0-jre17-temurin

# Remove default Tomcat webapps so ours is the only thing served
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy the WAR as ROOT so the app is served at "/" instead of "/<artifact-name>"
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
