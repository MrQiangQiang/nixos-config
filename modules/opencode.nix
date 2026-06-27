{ ... }:
{
  age.secrets.opencode-go-key = {
    file = ../secrets/opencode-go-key.age;
    owner = "fugui";
    group = "users";
  };
  age.secrets.deepseek-key = {
    file = ../secrets/deepseek-key.age;
    owner = "fugui";
    group = "users";
  };
  age.secrets.glm-coding-plan-key = {
    file = ../secrets/glm-coding-plan-key.age;
    owner = "fugui";
    group = "users";
  };
}
