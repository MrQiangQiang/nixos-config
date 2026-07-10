{ checkConflicts }:

{
  tier = "documented";
  desc = "Vim (已降级) — 仅系统恢复使用，主编辑器已切换为 Helix";
  bindings = checkConflicts "vim" [
    {
      desc = "左移";
      alias = "left";
      key = "h";
      mods = [ ];
      category = "move";
    }
    {
      desc = "下移";
      alias = "down";
      key = "j";
      mods = [ ];
      category = "move";
    }
    {
      desc = "上移";
      alias = "up";
      key = "k";
      mods = [ ];
      category = "move";
    }
    {
      desc = "右移";
      alias = "right";
      key = "l";
      mods = [ ];
      category = "move";
    }
    {
      desc = "下一词首";
      alias = "word next";
      key = "w";
      mods = [ ];
      category = "move";
    }
    {
      desc = "上一词首";
      alias = "word back";
      key = "b";
      mods = [ ];
      category = "move";
    }
    {
      desc = "行首/行尾";
      alias = "line start end";
      key = "0";
      mods = [ ];
      category = "move";
    }
    {
      desc = "文件首/末行";
      alias = "file top bottom";
      key = "g";
      mods = [ ];
      category = "move";
      mode = "gg/G";
    }
    {
      desc = "下翻半页";
      alias = "page down half";
      key = "d";
      mods = [ "Ctrl" ];
      category = "move";
    }
    {
      desc = "上翻半页";
      alias = "page up half";
      key = "u";
      mods = [ "Ctrl" ];
      category = "move";
    }
    {
      desc = "插入(光标前)";
      alias = "insert before";
      key = "i";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "插入(光标后)";
      alias = "insert after append";
      key = "a";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "插入(下方新行)";
      alias = "insert new line below open";
      key = "o";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "删除(剪切)行";
      alias = "delete cut line";
      key = "d";
      mods = [ ];
      category = "edit";
      mode = "dd";
    }
    {
      desc = "复制行";
      alias = "yank copy line";
      key = "y";
      mods = [ ];
      category = "edit";
      mode = "yy";
    }
    {
      desc = "粘贴";
      alias = "paste";
      key = "p";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "撤销";
      alias = "undo";
      key = "u";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "搜索";
      alias = "search find";
      key = "/";
      mods = [ ];
      category = "search";
    }
    {
      desc = "水平分屏";
      alias = "split horizontal";
      key = "s";
      mods = [ "Ctrl" ];
      category = "window";
      mode = "Ctrl+w s";
    }
    {
      desc = "垂直分屏";
      alias = "split vertical";
      key = "v";
      mods = [ "Ctrl" ];
      category = "window";
      mode = "Ctrl+w v";
    }
    {
      desc = "退出";
      alias = "quit";
      key = "q";
      mods = [ ];
      category = "session";
      mode = ":q";
    }
  ];
}
