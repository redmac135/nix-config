{
  config,
  lib,
  pkgs,
  ...
}: {
  home.username = "ezhao";
  home.homeDirectory = "/home/ezhao";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    BROWSER = "explorer.exe";
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
    esptool
    python3
    gcc
    gnumake
    pkg-config
    zlib.dev
    openssl.dev
    gnupg
    mise
    uv

    # Language Servers (LSPs)
    lua-language-server
    vscode-langservers-extracted # html, css, json
    dockerfile-language-server
    yaml-language-server
    svelte-language-server
    typescript-language-server
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
    jq
    supabase-cli

    # https://github.com/numtide/llm-agents.nix
    llmAgents.codex
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
    extraPackages = [pkgs.copilot-language-server];

    # Pre-compile Tree-sitter parsers into the Nix store
    plugins = let
      copilotLua = pkgs.vimPlugins.copilot-lua.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "zbirenbaum";
          repo = "copilot.lua";
          rev = "refs/tags/v3.0.0";
          hash = "sha256-lfma6pmMPVs4AOwkj69UoSI6Ue7RW4rOuwa1+G5UJ50=";
        };
      };
    in
      with pkgs.vimPlugins; [
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
        copilotLua
        (copilot-cmp.overrideAttrs {
          dependencies = [copilotLua];
        })
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
      eval "$(mise activate zsh)"

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

  home.activation.miseInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export HOME=${config.home.homeDirectory}
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    export CPATH="${config.home.profileDirectory}/include''${CPATH:+:$CPATH}"
    export LIBRARY_PATH="${config.home.profileDirectory}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}"
    export PKG_CONFIG_PATH="${config.home.profileDirectory}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export NIX_LD="${pkgs.nix-ld}/libexec/nix-ld"
    export NIX_LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib"
    export MISE_GLOBAL_CONFIG_FILE="$HOME/.config/mise/config.toml"
    export MISE_NODE_GPG_VERIFY=true
    export MISE_VERBOSE=1
    running=$(${pkgs.systemd}/bin/systemctl --user list-units --type=service \
      --state=running --no-legend 'mise-install-*.service' 2>/dev/null || true)
    if [[ -z $running ]]; then
      unit="mise-install-$(${pkgs.coreutils}/bin/date +%s)-$$.service"
      echo "Starting $unit; inspect with systemctl --user status $unit"
      ${pkgs.coreutils}/bin/timeout --foreground --kill-after=5s 30s \
        ${pkgs.systemd}/bin/systemd-run --user --no-block --collect \
        --unit="$unit" --property=Type=oneshot \
        --property=TimeoutStartSec=30min \
        --setenv=HOME="$HOME" --setenv=PATH="$PATH" \
        --setenv=CPATH="$CPATH" --setenv=LIBRARY_PATH="$LIBRARY_PATH" \
        --setenv=PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
        --setenv=NIX_LD="$NIX_LD" --setenv=NIX_LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH" \
        --setenv=MISE_GLOBAL_CONFIG_FILE="$MISE_GLOBAL_CONFIG_FILE" \
        --setenv=MISE_NODE_GPG_VERIFY="$MISE_NODE_GPG_VERIFY" --setenv=MISE_VERBOSE=1 \
        -- ${pkgs.coreutils}/bin/timeout --foreground --kill-after=30s 30m \
        ${pkgs.mise}/bin/mise install --yes
    fi
  '';

  # ---------------------------------------------------------------------------
  # Files
  # ---------------------------------------------------------------------------

  xdg.configFile."mise/config.toml".source = ./files/mise/config.toml;
  home.file.".AGENTS.md".source = ./files/AGENTS.md;
  home.file.".CLAUDE.md".source = ./files/AGENTS.md;
}
