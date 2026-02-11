{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Ali";
      user.email = "sa.akhavani@gmail.com";
    };

    delta.enable = true;
    delta.options = {
      features = "dracula";
      navigate = true;
    };
  };
}
