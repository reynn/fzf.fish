# Supports overriding keymaps with appended user-specified bindings
# Always installs bindings for insert mode since for simplicity and b/c it has almost no side-effect
# https://gitter.im/fish-shell/fish-shell?at=60a55915ee77a74d685fa6b1
function fzf_configure_keymap --argument-names keymap_or_help --description "Change the key bindings for fzf.fish to the specified key sequences."
    # index 1 = directory, 2 = git_log, 3 = git_status, 4 = history, 5 = variables
    set --local key_sequences
    switch $keymap_or_help
        case conflictless_mnemonic
            set key_sequences \e\cf \e\cl \cs \cr \cv
        case simple_mnemonic
            set key_sequences \cf \cl \cs \cr \cv
        case simple_conflictless
            set key_sequences \co \cl \cg \er \ex
        case blank
            set key_sequences "" "" "" "" ""
        case -h --help
            _fzf_configure_keymap_help
            return
        case '*'
            echo "Invalid or missing keymap argument." 1>&2
            _fzf_configure_keymap_help
            return 22
    end

    set options_spec 'directory=?' 'git_log=?' 'git_status=?' 'history=?' 'variables=?'
    argparse --max-args=0 --ignore-unknown $options_spec -- $argv[2..] 2>/dev/null #argv[1] is the keymap
    if test $status -ne 0
        echo "Invalid option or more than one argument provided." 1>&2
        _fzf_configure_keymap_help
        return 22
    else
        set --query _flag_directory && set key_sequences[1] "$_flag_directory"
        set --query _flag_git_log && set key_sequences[2] "$_flag_git_log"
        set --query _flag_git_status && set key_sequences[3] "$_flag_git_status"
        set --query _flag_history && set key_sequences[4] "$_flag_history"
        set --query _flag_variables && set key_sequences[5] "$_flag_variables"
    end

    # If another keymap already exists, uninstall it first for a clean slate
    if functions --query _fzf_uninstall_keymap
        _fzf_uninstall_keymap
    end

    for mode in default insert
        test -n $key_sequences[1] && bind --mode $mode $key_sequences[1] __fzf_search_current_dir
        test -n $key_sequences[2] && bind --mode $mode $key_sequences[2] __fzf_search_git_log
        test -n $key_sequences[3] && bind --mode $mode $key_sequences[3] __fzf_search_git_status
        test -n $key_sequences[4] && bind --mode $mode $key_sequences[4] __fzf_search_history
        test -n $key_sequences[5] && bind --mode $mode $key_sequences[5] $_fzf_search_vars_command
    end

    function _fzf_uninstall_keymap --inherit-variable key_sequences
        bind --erase -- $key_sequences
        bind --erase --mode insert -- $key_sequences
    end
end