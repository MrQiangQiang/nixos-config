# 共享内容 SSOT：commands / skills / agents / context
# context = 常驻上下文（行为准则），写入各工具的全局 context 文件：
#   OpenCode/Codex → AGENTS.md (context 选项)
#   Claude Code    → ~/.claude/CLAUDE.md (context 选项)
#   Trae           → ~/.trae-cn/user_rules/<name>.md (home.file)
# 项目级 rules（条件加载，如 .claude/rules/、.trae/rules/）不通过此 SSOT 管理，
# 应在项目仓库中维护。
# 空集时对所有工具零副作用
# 架构参考：ai-nixCfg（lib 模式 + *Meta attrset 承载工具特定映射）+ i9wa4（SSOT 模式）
{ lib, pkgs, ... }:
let
  ## 读取 shared/ 目录下的 .md 源文件
  ## 路径相对于此文件（Nix 路径字面量特性）
  readContent = type: name: builtins.readFile (./shared + "/${type}/${name}.md");

  ## YAML frontmatter 生成器（来自 ai-nixCfg，支持 list/attrs，自动过滤 null/空值）
  mkFrontmatter =
    attrs:
    let
      formatValue =
        v:
        if builtins.isList v then
          "[${lib.concatMapStringsSep ", " (x: "\"${x}\"") v}]"
        else if builtins.isAttrs v then
          "\n${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: val: "  ${k}: ${val}") v)}"
        else if builtins.isBool v then
          (if v then "true" else "false")
        else
          v;
      filtered = lib.filterAttrs (_: v: v != null && v != "" && v != [ ] && v != { }) attrs;
      lines = lib.mapAttrsToList (k: v: "${k}: ${formatValue v}") filtered;
    in
    "---\n${lib.concatStringsSep "\n" lines}\n---\n";

  ## 生成 skill 目录（含 SKILL.md with frontmatter + 依赖文件）
  ## 支持多文件 skills（如 domain-modeling 的 CONTEXT-FORMAT.md、ADR-FORMAT.md）
  ## frontmatter 从 skillMeta 自动生成（SSOT），源文件只含 body
  ## Codex 专用：当 disable-model-invocation = true 时生成 agents/openai.yaml
  ##   （policy.allow_implicit_invocation=false，与 frontmatter 字段等效）
  ## OpenCode：不支持 disable-model-invocation（官方设计选择，非 bug）
  ##   全部 22 条 description 常驻上下文，接受此限制（详见 docs/ai-agent-architecture.md）
  mkSkillDir =
    name: meta:
    let
      srcDir = ./shared/skills/${name};
      srcFiles = builtins.readDir srcDir;
      skillMd = builtins.readFile "${srcDir}/SKILL.md";
      skillContent = mkFrontmatter (meta // { inherit name; }) + skillMd;
      skillFile = pkgs.writeText "${name}-SKILL.md" skillContent;
      depFileNames = lib.filterAttrs (
        filename: _: filename != "SKILL.md" && !(lib.hasPrefix "." filename)
      ) srcFiles;
      hasDisableModelInvocation = meta.disable-model-invocation or false;
      codexYaml = pkgs.writeText "${name}-openai.yaml" "policy:\n  allow_implicit_invocation: false\n";
    in
    pkgs.runCommand "${name}-skill" { } ''
      mkdir -p $out
      cp ${skillFile} $out/SKILL.md
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (filename: _: "cp -r ${srcDir}/${filename} $out/${filename}") depFileNames
      )}
      ${lib.optionalString hasDisableModelInvocation ''
        mkdir -p $out/agents
        cp ${codexYaml} $out/agents/openai.yaml
      ''}
    '';

  ## 内容元数据（当前为空，添加内容时在此注册）
  ## context（常驻上下文）硬性约束：
  ##   - 合计 ≤100 行（严于 ECC 309 行 advisory；ECC/Superpowers 源码验证：常驻越短模型遵循越可靠）
  ##   - 只放行为准则，不放方法论（方法论放 skill，按需加载）
  ##   - 少即是多：每加一条规则都摊薄已有规则的权重
  commandMeta = { };

  skillMeta = {
    research = {
      description = "Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent. - 原始来源调研/文档与 API 事实采集/后台 agent 代劳";
    };
    grill-me = {
      description = "A relentless interview to sharpen a plan or design. - 需求对齐/需求澄清/在编码前确认需求边界";
      disable-model-invocation = true;
    };
    grilling = {
      description = "Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases. - 追问/压力测试计划或设计";
    };
    grill-with-docs = {
      description = "A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go. - 需求+术语对齐/在追问过程中创建 ADR 和术语表";
      disable-model-invocation = true;
    };
    domain-modeling = {
      description = "Build and sharpen a project's domain model. Use when the user wants to pin down domain terminology or a ubiquitous language, record an architectural decision, or when another skill needs to maintain the domain model. - 术语对齐/领域建模/统一语言";
    };
    handoff = {
      description = "Compact the current conversation into a handoff document for another agent to pick up. - 上下文对齐/交接文档";
      disable-model-invocation = true;
      argument-hint = "What will the next session be used for?";
    };
    to-spec = {
      description = "Turn the current conversation into a spec and publish it to the project issue tracker — no interview, just synthesis of what you've already discussed. - 规格对齐/PRD 生成";
      disable-model-invocation = true;
    };
    to-tickets = {
      description = "Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker — edges as text in one file per ticket locally, or native blocking links on a real tracker. - 任务对齐/工单分解";
      disable-model-invocation = true;
    };
    code-review = {
      description = "Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes — Standards (does the code follow this repo's documented coding standards?) and Spec (does the code match what the originating issue/PRD asked for?). Runs both reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to \"review since X\". - 代码对齐/双轴审查";
    };
    ask-matt = {
      description = "Ask which skill or flow fits your situation. A router over the skills in this repo. - 意图对齐/skill 路由";
      disable-model-invocation = true;
    };
    implement = {
      description = "Implement a piece of work based on a spec or set of tickets. - 实现/基于规格或工单实现";
      disable-model-invocation = true;
    };
    tdd = {
      description = "Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions \"red-green-refactor\", or wants integration tests. - 测试驱动开发";
    };
    triage = {
      description = "Move issues and external PRs through a state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs. - 分诊/问题分类";
      disable-model-invocation = true;
    };
    diagnosing-bugs = {
      description = "Diagnosis loop for hard bugs and performance regressions. Use when the user says \"diagnose\"/\"debug this\", or reports something broken/throwing/failing/slow. - 调试/bug 诊断";
    };
    wayfinder = {
      description = "Plan a huge chunk of work — more than one agent session can hold — as a shared map of investigation tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear. - 路径规划/大型任务分解";
      disable-model-invocation = true;
    };
    improve-codebase-architecture = {
      description = "Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick. - 架构改进/代码库深化";
      disable-model-invocation = true;
    };
    codebase-design = {
      description = "Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or AI-navigable, or when another skill needs the deep-module vocabulary. - 模块设计/深度模块词汇";
    };
    prototype = {
      description = "Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like. - 原型/设计验证";
    };
    teach = {
      description = "Teach the user a new skill or concept, within this workspace. - 教学/概念学习";
      disable-model-invocation = true;
      argument-hint = "What would you like to learn about?";
    };
    writing-great-skills = {
      description = "Reference for writing and editing skills well — the vocabulary and principles that make a skill predictable. - 元技能/skill 编写参考";
      disable-model-invocation = true;
    };
    setup-matt-pocock-skills = {
      description = "Configure this repo for the engineering skills — set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills. - 前置配置/初始化";
      disable-model-invocation = true;
    };
    resolving-merge-conflicts = {
      description = "Use when you need to resolve an in-progress git merge/rebase conflict. - 合并冲突解决/rebase 冲突处理";
    };
  };
  ## skill 总量说明：
  ##   - 完整引入 mattpocock/skills 生态（22 个），保证 ask-matt 路由不断链
  ##   - Claude Code/Trae-CN：13 个 user-invoked skills 设 disable-model-invocation=true，
  ##     description 从模型上下文移除（零 context load）；9 个 model-invoked 常驻 ~270 tokens
  ##   - Codex：13 个 user-invoked skills 通过 agents/openai.yaml 设
  ##     allow_implicit_invocation=false（与 frontmatter 字段等效）
  ##   - OpenCode：忽略 disable-model-invocation（官方限制），22 条 description 全常驻 ~660 tokens
  ##   - skill 按需加载（progressive disclosure），只在任务相关时加载全文
  ##   - 对齐类 skills 是人与 AI 交接点的基础设施，跨项目通用（用户级）
  ##   - MCP tool schema 每会话常驻，每个工具 ~500 tokens；新增必须通过 ECC 两轮测试
  ##     (Universal + MCP-genuinely-beats-CLI)，否则用 skill 包 CLI
  agentMeta = { };
  contextNames = [ "guidelines" ];

  ## 构建各工具消费的 attrset（name 由 key 自动注入，所有 meta 字段透传到 frontmatter）
  commands = lib.mapAttrs (name: meta: mkFrontmatter meta + readContent "commands" name) commandMeta;

  ## skills = attrsOf path（每个 skill 是一个 nix store 目录，含 SKILL.md + 依赖文件）
  ## hm 模块（claude-code/codex/opencode）直接用 path，自动处理多文件
  ## Trae 通过 home.file + recursive = true 注入
  skills = lib.mapAttrs mkSkillDir skillMeta;

  agents = lib.mapAttrs (
    name: meta: mkFrontmatter (meta // { inherit name; }) + readContent "agents" name
  ) agentMeta;

  context = builtins.listToAttrs (
    map (name: lib.nameValuePair name (readContent "context" name)) contextNames
  );

  ## 合并所有 context（供各工具 context 选项使用）
  combinedContext = lib.concatStringsSep "\n\n---\n\n" (builtins.attrValues context);
in
{
  inherit
    commands
    skills
    agents
    context
    combinedContext
    ;
}
