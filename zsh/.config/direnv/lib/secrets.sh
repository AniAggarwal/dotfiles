# direnv helper: export secrets from the Secret Service (KeePassXC) for this directory only.
# In a project's .envrc:   use secret HF_TOKEN WANDB_API_KEY
# Each NAME is looked up with `secret-tool lookup env NAME` (stored by secrets-import).
use_secret() {
    local name value
    for name in "$@"; do
        if value=$(secret-tool lookup env "$name"); then
            export "$name=$value"
        else
            log_error "secret $name not found (is KeePassXC unlocked?)"
        fi
    done
}
