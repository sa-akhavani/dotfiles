{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Ali";
    userEmail = "sa.akhavani@gmail.com";
    delta.enable = true;
    delta.options = {
      features = "dracula";
      navigate = true;
    };
  };
}
