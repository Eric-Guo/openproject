FROM node:22.18
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN npm install -g pnpm@10.33.0 && pnpm install --frozen-lockfile --prod
COPY src/ /app/src
EXPOSE 1234

# Start the app
CMD ["pnpm", "start", "--", "--no-daemon"]
