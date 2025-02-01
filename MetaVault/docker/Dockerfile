# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files
COPY *.sln .
COPY src/MetaVault.Web/*.csproj ./src/KilnMetaVault.Web/
COPY src/MetaVault.Shared/*.csproj ./src/KilnMetaVault.Shared/
COPY src/MetaVault.Contracts/*.csproj ./src/KilnMetaVault.Contracts/

# Restore dependencies
RUN dotnet restore

# Copy the rest of the source code
COPY . .

# Publish the application
WORKDIR /src/src/KilnMetaVault.Web
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Runtime
FROM nginx:alpine AS runtime
WORKDIR /usr/share/nginx/html

# Copy the published files from build stage
COPY --from=build /app/publish/wwwroot .

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]