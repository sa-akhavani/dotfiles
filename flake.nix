{
  description = "Ali's Flakes";

  inputs = {
    # NixOS official package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      #     url = "github:nix-community/home-manager";

      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      claude-code,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {

        #        rostam = nixpkgs.lib.nixosSystem {
        #          inherit system;
        #          specialArgs = {
        #            inherit inputs;
        #          };
        #          modules = [
        #            ./hosts/rostam/configuration.nix
        #
        #            home-manager.nixosModules.home-manager
        #            {
        #              home-manager.useGlobalPkgs = true;
        #              home-manager.useUserPackages = true;
        #              home-manager.users.ali = import ./hosts/rostam/home.nix;
        #              home-manager.extraSpecialArgs = {
        #                inherit inputs;
        #                inherit pkgs-unstable;
        #              };
        #            }
        #          ];
        #        };
        #
        sohrab = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/sohrab/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit pkgs-unstable;
              };
              home-manager.users.ali = import ./hosts/sohrab/home.nix;

              # pkgs.claude-code is available everywhere
              nixpkgs.overlays = [ inputs.claude-code.overlays.default ];
            }
          ];
        };

      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      #	     homeConfigurations = {
      #		ali = home-manager.lib.homeManagerConfiguration {
      #			inherit pkgs;
      #			modules = [ ./home ];
      #			extraSpecialArgs = {
      #			    inherit pkgs;
      #			    inherit inputs;
      #			};
      #		};
      #	    };

    };
}
