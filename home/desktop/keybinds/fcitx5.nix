{ checkConflicts }:

{
  tier = "documented";
  desc = "Fcitx5 — 输入法框架快捷键，IME 开启时跨应用生效";
  bindings = checkConflicts "fcitx5" [
    {
      desc = "简繁切换";
      alias = "simplified traditional toggle";
      key = "f";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "ime";
    }
    {
      desc = "中/英切换";
      alias = "zh en toggle";
      key = "Shift";
      mods = [ ];
      category = "ime";
    }
    {
      desc = "切换输入法";
      alias = "ime toggle";
      key = "Space";
      mods = [ "Ctrl" ];
      category = "ime";
    }
  ];
}
