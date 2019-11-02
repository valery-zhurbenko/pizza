FROM node:8-jessie

COPY . /app
WORKDIR /app
RUN npm install
RUN npm test
CMD node server.js
