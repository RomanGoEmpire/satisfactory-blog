# Use the official Node.js LTS image as a base
FROM node:lts AS base

# Install pnpm globally
RUN npm install -g pnpm

# Set the working directory in the container
WORKDIR /app

# By copying only the package.json and pnpm-lock.yaml here, we ensure that the following `-deps` steps are independent of the source code.
# Therefore, the `-deps` steps will be skipped if only the source code changes.
COPY package.json pnpm-lock.yaml ./

# Install production dependencies using pnpm
FROM base AS prod-deps
RUN pnpm install --prod --frozen-lockfile

# Install all dependencies (including devDependencies) using pnpm
FROM base AS build-deps
RUN pnpm install --frozen-lockfile

# Build the Astro application
FROM build-deps AS build
COPY . .
RUN pnpm run build

# Create the final runtime image
FROM base AS runtime

# Copy production node_modules from the prod-deps stage
COPY --from=prod-deps /app/node_modules ./node_modules

# Copy the built application from the build stage
COPY --from=build /app/dist ./dist

# Set environment variables for the server
ENV HOST=0.0.0.0
ENV PORT=4321

# Expose the port the app runs on
EXPOSE 4321

# Define the command to run the application
CMD ["node", "./dist/server/entry.mjs"]
