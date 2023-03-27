# Just currently loads the `.env` file, but that will be changing, so we
# are disabling it now since we do not need the functionality.
set dotenv-load := false

_default:
    @just --list

# Validate the nginx config.
validate:
    @docker build -t dialtun .
    @docker run -it --rm \
        --entrypoint "/usr/bin/openresty" \
        dialtun \
            -t

# Run dialtun (including Tailscale).
run:
    @docker build -t dialtun .
    @docker run -it --rm -p 8080:8080 --env-file .env dialtun