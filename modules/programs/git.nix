{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Ali";
      user.email = "sa.akhavani@gmail.com";
    };
  };

  programs.delta = {
    enable = true;
    options = {
      features = "dracula";
      navigate = true;
    };
  };
}
