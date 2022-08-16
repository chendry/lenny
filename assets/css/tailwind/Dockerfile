FROM node:12

VOLUME /lenny
WORKDIR /lenny/assets/css/tailwind

ENTRYPOINT []

RUN npm install --global \
  tailwindcss@3.1.8 \
  @tailwindcss/forms@0.5.2 \
  autoprefixer \
  postcss

ENV NODE_ENV=production
ENV NODE_PATH=/usr/local/lib/node_modules

CMD tailwindcss \
  -i ./tailwind.css \
  -c ./tailwind.config.js \
  -o ../tailwind.css \
  --watch
