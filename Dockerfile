FROM nixos/nix

WORKDIR /app
COPY . .

EXPOSE 8000

RUN nix --extra-experimental-features nix-command --extra-experimental-features flakes build
ENTRYPOINT ["sh", "-c", "nix --extra-experimental-features nix-command --extra-experimental-features flakes run"]