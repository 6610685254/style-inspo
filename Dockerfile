# ---------- Stage 1: Build Flutter Web ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pub files first (better caching)
COPY pubspec.* ./
RUN flutter pub get

# Copy full project
COPY . .

# Build web release
RUN flutter build web --release


# ---------- Stage 2: Serve with Nginx ----------
FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy Flutter build output
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
