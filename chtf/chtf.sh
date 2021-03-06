# Copyright (c) 2012-2016 Hal Brodigan
# Copyright (c) 2016-2018 Yleisradio Oy
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

: "${CASKROOM:=$(brew --prefix)/Caskroom}"

chtf() {
    case "$1" in
        -h|--help)
            echo "usage: chtf [VERSION | system]"
            ;;
        -V|--version)
            echo "chtf: ${CHTF_VERSION:-[unknown version]}"
            ;;
        "")
            _chtf_list
            ;;
        system)
            _chtf_reset
            ;;
        *)
            _chtf_use "$1"
            ;;
    esac
}

_chtf_reset() {
    [[ -z "$CHTF_CURRENT" ]] && return 0

    PATH=":$PATH:"; PATH="${PATH//:$CHTF_CURRENT:/:}"
    PATH="${PATH#:}"; PATH="${PATH%:}"
    hash -r

    unset CHTF_CURRENT
    unset CHTF_CURRENT_TERRAFORM_VERSION
}

_chtf_install() {
    echo "chtf: Installing Terraform version $1"
    brew cask install "terraform-$1"
}

_chtf_use() {
    local tf_path="$CASKROOM/terraform-$1/$1"

    [[ -d "$tf_path" ]] || _chtf_install "$1" || return 1

    if [[ ! -x "$tf_path/terraform" ]]; then
        echo "chtf: $tf_path/terraform not executable" >&2
        return 1
    fi

    _chtf_reset

    export CHTF_CURRENT="$tf_path"
    export CHTF_CURRENT_TERRAFORM_VERSION="$1"
    export PATH="$CHTF_CURRENT:$PATH"
}

_chtf_list() (
    # Avoid glob matching errors.
    # Note that we do this in a subshell to restrict the scope.
    # bash
    shopt -s nullglob 2>/dev/null || true
    # zsh
    setopt null_glob 2>/dev/null || true

    for dir in "$CASKROOM"/terraform-*/*; do
        if [[ "$dir" == "$CHTF_CURRENT" ]]; then
            echo " * $(basename "$dir")"
        else
            echo "   $(basename "$dir")"
        fi
    done;
)

_chtf_root_dir() {
    if [[ -n "$BASH" ]]; then
        dirname "${BASH_SOURCE[0]}"
    elif [[ -n "$ZSH_NAME" ]]; then
        dirname "${(%):-%x}"
    else
        echo 'chtf: [WARN] Unknown shell' >&2
    fi
}

# Load and store the version number
CHTF_VERSION=$(cat "$(_chtf_root_dir)/VERSION" 2>/dev/null)
