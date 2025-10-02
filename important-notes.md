#### Error: Path not found issue
If you are using `nix-rebuild switch` but having issues with path not found for modules that are defined in a relative path and imported in configuration.nix or flake.nix, the issue is that those files are not "commited" or "tracked" in the git repository. Commit or add them and then run the command again!

