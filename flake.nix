{
  description = "Flake utils demo";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;
        inputs = pypkgs: [
          pypkgs.typer
          pypkgs.rich
          pypkgs.pydantic
          pypkgs.pyyaml
        ];
        version = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./version);
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = [
              (pkgs.python312.withPackages (pypkgs: (inputs pypkgs) ++ [pypkgs.mypy pypkgs.types-pyyaml]))
              pkgs.ruff
            ];
          };
        };
        packages = rec {
          default = python.pkgs.buildPythonApplication {
            pname = "mp2-validator";
            version = version;
            propagatedBuildInputs = inputs python.pkgs;
            src = ./.;
          };
          docker = pkgs.dockerTools.buildLayeredImage {
            name = "ghcr.io/charmoniumQ/mp2-validator";
            tag = version;
            contents = self.packages.${system}.default;
            config = {
              Entrypoint = "${self.packages.${system}.default}/bin/main.py";
            };
          };
        };
        apps = rec {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/main.py";
          };
        };
      }
    );
}
