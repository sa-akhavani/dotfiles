{ ... }:
{
  programs.git = {
    enable = true;
    userEmail = "sa.akhavani@gmail.com";
    userName = "sa-akhavani";
    delta.enable = true;
    delta.options = {
      features = "dracula";
      navigate = true;
    };
  };
}
