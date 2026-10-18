FROM nginx:alpine
ARG BUILD=dev
COPY index.html /usr/share/nginx/html/index.html
RUN sed -i "s/__BUILD__/${BUILD}/" /usr/share/nginx/html/index.html
