{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "Helix — 主编辑器的 Normal 模式核心操作，selection→action 模型。完整快捷键见 :help 和 hx --tutor";

  bindings = checkConflicts "helix" [
    # --- move ---
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
      desc = "下一词尾";
      alias = "word end next";
      key = "e";
      mods = [ ];
      category = "move";
    }
    {
      desc = "文件首";
      alias = "file top";
      key = "g";
      mods = [ ];
      category = "move";
      mode = "gg";
    }
    {
      desc = "文件尾";
      alias = "file bottom";
      key = "G";
      mods = [ ];
      category = "move";
    }
    {
      desc = "上翻一页";
      alias = "page up";
      key = "u";
      mods = [ "Ctrl" ];
      category = "move";
    }
    {
      desc = "下翻一页";
      alias = "page down";
      key = "d";
      mods = [ "Ctrl" ];
      category = "move";
    }
    {
      desc = "匹配括号";
      alias = "match bracket";
      key = "Percent";
      mods = [ ];
      category = "move";
    }
    {
      desc = "行首非空";
      alias = "line start nonblank";
      key = "g";
      mods = [ ];
      category = "move";
      mode = "g_";
    }

    # --- selection ---
    {
      desc = "进入/退出选择模式";
      alias = "select toggle";
      key = "x";
      mods = [ ];
      category = "select";
    }
    {
      desc = "扩选模式";
      alias = "extend select";
      key = "v";
      mods = [ ];
      category = "select";
    }
    {
      desc = "按搜索拆分选择";
      alias = "split select search";
      key = "s";
      mods = [ ];
      category = "select";
    }
    {
      desc = "折叠选择到光标";
      alias = "collapse select";
      key = "semicolon";
      mods = [ ];
      category = "select";
    }
    {
      desc = "全选";
      alias = "select all";
      key = "a";
      mods = [ "Ctrl" ];
      category = "select";
    }
    {
      desc = "下一个匹配词/选相同词 (同键)";
      alias = "next match";
      key = "n";
      mods = [ ];
      category = "select";
    }
    {
      desc = "跳过当前选中词";
      alias = "select skip word";
      key = "Alt+n";
      mods = [ ];
      category = "select";
    }

    # --- edit ---
    {
      desc = "插入(光标前)";
      alias = "insert before";
      key = "i";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "插入(光标后)";
      alias = "insert after";
      key = "a";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "插入(行首)";
      alias = "insert line start";
      key = "I";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "插入(行尾)";
      alias = "insert line end";
      key = "A";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "下方新行";
      alias = "open below";
      key = "o";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "上方新行";
      alias = "open above";
      key = "O";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "删除";
      alias = "delete";
      key = "d";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "修改(删除+插入)";
      alias = "change";
      key = "c";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "复制(yank)";
      alias = "yank";
      key = "y";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "粘贴后";
      alias = "paste after";
      key = "p";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "粘贴前";
      alias = "paste before";
      key = "P";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "替换字符";
      alias = "replace char";
      key = "r";
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
      desc = "重做";
      alias = "redo";
      key = "z";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "右缩进";
      alias = "indent right";
      key = "Greater";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "左缩进";
      alias = "indent left";
      key = "Less";
      mods = [ ];
      category = "edit";
    }

    # --- search ---
    {
      desc = "搜索(前进)";
      alias = "search forward";
      key = "Slash";
      mods = [ ];
      category = "search";
    }
    {
      desc = "搜索(后退)";
      alias = "search backward";
      key = "?";
      mods = [ ];
      category = "search";
    }
    {
      desc = "上一个匹配";
      alias = "prev match";
      key = "N";
      mods = [ ];
      category = "search";
    }
    {
      desc = "选中词搜索";
      alias = "search selection";
      key = "Asterisk";
      mods = [ ];
      category = "search";
    }

    # --- file / session ---
    {
      desc = "保存文件";
      alias = "save";
      key = "w";
      mods = [ ];
      category = "session";
      mode = "Space+w";
    }
    {
      desc = "退出";
      alias = "quit";
      key = "q";
      mods = [ ];
      category = "session";
      mode = "Space+q";
    }
    {
      desc = "文件选择器";
      alias = "file picker";
      key = "f";
      mods = [ ];
      category = "session";
      mode = "Space+f";
    }
    {
      desc = "打开文件";
      alias = "file open cmd";
      key = "w";
      mods = [ ];
      category = "session";
      mode = ":o";
    }

    # --- window ---
    {
      desc = "左移窗口";
      alias = "window left";
      key = "h";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w h";
    }
    {
      desc = "下移窗口";
      alias = "window down";
      key = "j";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w j";
    }
    {
      desc = "上移窗口";
      alias = "window up";
      key = "k";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w k";
    }
    {
      desc = "右移窗口";
      alias = "window right";
      key = "l";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w l";
    }
    {
      desc = "垂直分屏";
      alias = "split vertical";
      key = "v";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w v";
    }
    {
      desc = "水平分屏";
      alias = "split horizontal";
      key = "s";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w s";
    }
    {
      desc = "关闭窗口";
      alias = "window close";
      key = "q";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w q";
    }
    {
      desc = "切换窗口";
      alias = "window cycle";
      key = "w";
      mods = [ ];
      category = "window";
      mode = "Ctrl+w w";
    }

    # --- go to (g prefix) ---
    {
      desc = "跳转到定义";
      alias = "goto definition";
      key = "d";
      mods = [ ];
      category = "goto";
      mode = "gd";
    }
    {
      desc = "跳转到引用";
      alias = "goto references";
      key = "r";
      mods = [ ];
      category = "goto";
      mode = "gr";
    }
    {
      desc = "跳转到类型定义";
      alias = "goto type def";
      key = "t";
      mods = [ ];
      category = "goto";
      mode = "gt";
    }
    {
      desc = "跳转到实现";
      alias = "goto implementation";
      key = "i";
      mods = [ ];
      category = "goto";
      mode = "gi";
    }
    {
      desc = "跳转到诊断";
      alias = "goto diagnostic next";
      key = "d";
      mods = [ ];
      category = "goto";
      mode = "]d";
    }
    {
      desc = "文档悬浮";
      alias = "hover doc";
      key = "K";
      mods = [ ];
      category = "goto";
    }
    {
      desc = "符号搜索";
      alias = "symbol picker";
      key = "s";
      mods = [ ];
      category = "goto";
      mode = "Space+s";
    }
  ];
}
