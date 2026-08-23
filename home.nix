{
  config,
  pkgs,
  ...
}: {
  home.username = "ezhao";
  home.homeDirectory = "/home/ezhao";
  home.stateVersion = "26.05";
  home.sessionVariables = {
    BROWSER = "explorer.exe";
    NPM_CONFIG_PREFIX = "$HOME/.local";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.packages = with pkgs; [
    # Core
    git
    fd
    ripgrep # required for neovim search / telescope
    chromium
    lazygit
    lazydocker
    cloudflared
    gcc
    gnumake

    # Language Runtimes
    nodejs_22
    python312
    deno
    bun
    go
    cargo
    rustc

    # Language Servers (LSPs)
    lua-language-server
    vscode-langservers-extracted # html, css, json
    dockerfile-language-server
    yaml-language-server
    svelte-language-server
    pyright
    nil # nix LSP
    bash-language-server
    clang-tools # provides clangd and clang-format
    cmake-language-server
    rust-analyzer

    # Formatters & Linters
    ruff # replaces black + python linter
    stylua # lua formatter
    prettierd
    alejandra # nix formatter

    # Utilities
    gh
    taskwarrior3

    # https://github.com/numtide/llm-agents.nix
    llmAgents.opencode
    llmAgents.herdr
    (llmAgents.pi.override {useBun = false;})

    # kunchenguid
    treehouse.default
    firstmate.no-mistakes
    firstmate.gh-axi
    firstmate.chrome-devtools-axi
    firstmate.lavish-axi
    firstmate.tasks-axi
    firstmate.quota-axi
  ];

  # ---------------------------------------------------------------------------
  # Program configs
  # ---------------------------------------------------------------------------
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Ethan Zhao";
        email = "ethan.yzhao@outlook.com";
      };
      core.editor = "neovim";
      color.ui = true;
      push.autoSetupRemote = true;
      pull.rebase = true;
      rebase.updateRefs = true;
      credential."https://github.com".helper = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Pre-compile Tree-sitter parsers into the Nix store
    plugins = with pkgs.vimPlugins; [
      # UI & Theme
      snacks-nvim
      catppuccin-nvim
      oil-nvim

      # LSP & Formatting
      nvim-lspconfig
      conform-nvim

      # Mini suite
      mini-nvim

      # Completion & Snippets
      nvim-cmp
      cmp-nvim-lsp
      luasnip
      friendly-snippets

      # Treesitter
      nvim-ts-autotag
      (nvim-treesitter.withPlugins (p: [
        p.bash
        p.c
        p.cpp
        p.css
        p.dockerfile
        p.go
        p.html
        p.javascript
        p.json
        p.lua
        p.nix
        p.python
        p.rust
        p.svelte
        p.typescript
        p.yaml
      ]))
    ];
  };

  # Symlink Neovim config directory
  xdg.configFile."nvim".source = ./nvim;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = builtins.fromTOML (
      builtins.readFile "${pkgs.starship}/share/starship/presets/nerd-font-symbols.toml"
    );
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    history = {
      size = 1000;
      save = 1000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignorePatterns = [
        "exit"
        "cd"
        "ls"
        "bg"
        "fg"
        "history"
        "f"
        "fd"
        "vim"
      ];
    };

    shellAliases = {
      vim = "nvim";
      cls = "clear";
      ll = "ls -la --color=auto";
      lzd = "lazydocker";
      lg = "lazygit";

      # WSL shortcut
      shutdown = "wsl.exe --shutdown";
    };

    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    initContent = ''
      # Autosuggestions strategy
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

      # Enable menu selection for completions
      zstyle ':completion:*' menu select

      # Edit command line widget (Ctrl+X, then E to edit command in Neovim)
      autoload -U edit-command-line
      zle -N edit-command-line
      bindkey '^Xe' edit-command-line
    '';
  };

  programs.home-manager.enable = true;

  # ---------------------------------------------------------------------------
  # Files
  # ---------------------------------------------------------------------------

  home.file.".AGENTS.md".source = ./files/AGENTS.md;
  home.file.".CLAUDE.md".source = ./files/AGENTS.md;
}
