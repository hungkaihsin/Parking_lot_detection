#!/bin/bash
# This script sets the GIT_SHA environment variable and then runs docker-compose.
# This provides a simple way for the team to build and run the application
# without needing to remember the full command.

export GIT_SHA=$(git rev-parse --short HEAD)
docker-compose up --build -d "$@"
