FROM node:15 as build-stage

# Create work directory => /usr/src/app

ENV APP_HOME=/usr/src/app
WORKDIR $APP_HOME

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)

COPY package.json $APP_HOME
COPY package-*.json $APP_HOME

RUN npm install

# If we are building for production
COPY . $APP_HOME
RUN npm ci --only-production && npm run build

# Production Stage
FROM nginx:stable-alpine as production-stage

ENV APP_HOME=/usr/src/app

# Copy build artifacts to production stage
COPY --from=build-stage $APP_HOME/dist /usr/share/nginx/html

# Copy nginx configuration
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Change ownership of /usr/share/nginx/html to nginx
RUN chown nginx:nginx /usr/share/nginx/html

# set environment variable for port
ENV PORT=80

# Expose our app port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
