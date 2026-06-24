FROM node:20-bullseye
WORKDIR /app
RUN apt update && apt install git
RUN apt update && apt install -y git && rm -rf /var/lib/apt/lists/*

RUN rm -rf /app/* && if [ ! -d "/app/.git" ]; then git clone https://github.com/dedkola/nextjs-docs.git /app; else cd /app && git pull; fi

RUN npm install
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]


