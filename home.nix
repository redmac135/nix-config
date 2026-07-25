{
  config,
  pkgs,
  ...
}: {
  home.username = "ezhao";
  home.homeDirectory = "/home/ezhao";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Core
    git
    fd
    lazygit
    lazydocker

    # Language Runtimes
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

    # Formatters & Linters
    ruff # replaces black + python linter
    stylua # lua formatter
    prettierd
    alejandra # nix formatter
  ];

  # ---------------------------------------------------------------------------
  # Neovim & Tree-sitter Grammars
  # ---------------------------------------------------------------------------
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Pre-compile Tree-sitter parsers into the Nix store
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (grammars:
        with grammars; [
          tree-sitter-bash
          tree-sitter-c
          tree-sitter-cpp
          tree-sitter-css
          tree-sitter-dockerfile
          tree-sitter-html
          tree-sitter-javascript
          tree-sitter-json
          tree-sitter-lua
          tree-sitter-python
          tree-sitter-rust
          tree-sitter-svelte
          tree-sitter-typescript
          tree-sitter-yaml
          tree-sitter-go
          tree-sitter-nix
        ]))
    ];
  };

  # Symlink Neovim config directory
  xdg.configFile."nvim".source = ./nvim;

  # ---------------------------------------------------------------------------
  # Shell Integrations
  # ---------------------------------------------------------------------------

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
      ignorePatterns = [ "exit" "cd" "ls" "bg" "fg" "history" "f" "fd" "vim" ];
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
  };

  programs.home-manager.enable = true;
}
