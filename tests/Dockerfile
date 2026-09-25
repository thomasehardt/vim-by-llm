FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash tester
USER tester
WORKDIR /home/tester

# Pre-existing config, to check it gets backed up rather than clobbered.
RUN echo '" my old vimrc' > /home/tester/.vimrc

# Copy the local repo so unpushed changes are tested, not what's on GitHub.
COPY --chown=tester:tester . /home/tester/vim-config-repo

CMD ["/bin/bash", "-c", "set -e; cd vim-config-repo && git init -q 2>/dev/null; git add -A && git -c user.email=t@t -c user.name=t commit -qm test >/dev/null || true; cd; export REPO_URL=/home/tester/vim-config-repo && bash vim-config-repo/install.sh && export PATH=$HOME/.local/bin:$PATH && vim-mgr status && grep -q 'my old vimrc' ~/.vim-backup-*/.vimrc && echo '✓ old vimrc backed up' && bash ~/.local/share/vim-mgr/tests/test-config.sh"]
