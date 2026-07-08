{ ... }:

let
  owner = "fugui";
  group = "users";
in
{
  age.secrets.opencode-go-key = {
    file = ../secrets/opencode-go-key.age;
    inherit owner group;
  };
  age.secrets.deepseek-key = {
    file = ../secrets/deepseek-key.age;
    inherit owner group;
  };
  age.secrets.glm-coding-plan-key = {
    file = ../secrets/glm-coding-plan-key.age;
    inherit owner group;
  };
}
