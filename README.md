# Welcome to my dotfiles!

### Introduction

**This repo is designed to be useful to others, even if their setup is completely different from mine!**  

Rather than just a set of my personal dotfiles, you will also find a toolkit and process on top of which the replication of arbitrary personal setups can be conveniently automated by writing simple and portable scripts.

### Structure

The `main` branch contains my personal configurations both for my own convenience and so that visitors are greeted with a substancial and realistic example as reference. Visitors are naturally welcome to take inspiration from or simply copy what I do.

The `blank` branch will contain all the utilities of the generic setup toolkit without any of my personal configurations. It serves as a starting point for visitors to fork, branch, and integrate their own setup requirements into.

### Privacy

Some dotfiles and other setup details can be very sensitive. Obvious examples include gpg private keys or ssh configs for specific servers. The approach I follow for these cases is to keep that data outside of this project but to keep hooks within this project so that those private details can be conveniently integrated into the repo without being committed to it or otherwise tracked. For clear examples, please refer to how I use include directives in both my ssh and gpg configs.

### Reference

##### Getting Started

Currently, `bash` is the only supported way of using this project, and that will likely not change any time soon.

The general workflow is to write a setup procedure as a bash script that utilizes the documented tools. This script will be run with `./setup.sh <path/to/setup/procedure>`. This will ensure that all the documented tools are available as the setup procedure is executed.  

One can also `source ./setup.sh` into the shell without providing a setup procedure script to directly access and interactively experiment with the provided tools.  

##### Environment Variables
- **$REPO_PATH**: The repository root of the `setup.sh` script (ie. this repo). Useful for writing scripts that have the same behaviour regardless of where they are invoked from.  
- **$CONFIG_SCRIPT_PATH**: The `realpath` of the setup procedure script that was provided when running `setup.sh`. Unspecified if `setup.sh` was sourced.  
- **$SETUP_DIR**: The directory that this toolkit uses to store data related to its own execution.  
- **$BACKUP_DIR**: The directory where the backups associated with a particular invocation of `setup.sh` are stored. Guaranteed to be under `$SETUP_DIR`.  
- **$DISTRO_NAME**: The name of the running Linux distribution, currently supported:  
    - Ubuntu  
- **$PACKAGE_MANAGER**: The name of the system's recognized Linux package manager, currently supported:  
    - apt  
- **$IM_IN_WSL**: `true` if your are running bash in Windows Subsystem for Linux, `false` otherwise.  

##### Functions
- `update_package_manager`: Updates the repositories for your package manager, like `sudo apt update && sudo apt upgrade` but distribution agnostic.
- `install_package <package-name>`: Install a package, like `sudo apt install <package-name>` but distribution agnostic.
- `ensure_containing_dir <path>`: Creates directories such that the creation of a file at the given path is possible.
- `ensure_inside <target> <container>`: Returns zero status code if the target is under the container in the file hierarchy, and non-zero otherwise. Resillient to complications such as symlink resolution and `../` notation.
- `ensure_outside <target> <container>`: Returns zero status code if the target is outside of and not equivalent to the container in the file hierarchy. Returns non-zero otherwise. Resillient to complications such as symlink resolution and `../` notation.
- `backup_item <source> <destination>`: Creates a backup of the given source at the given destination. The destination MUST be within `$BACKUP_DIR`.
- `deploy_item <source> <destination>`: Meant for deploying config files from inside the repository into the system. The source must be inside the repo and the destination must be outside of it. A symlink will be set at the destination pointing to the source in the repo so that in-place changes to deployed files will be tracked by git. If source is relative it will be interpreted relative to `pwd`, which is `$REPO_PATH` by default during execution of procedure scripts. Backups of existing content at the destination will be made before overwriting.
- `deploy_item_wsl <source> <destination>`: Similar to `deploy_item` but meant for deploying files into the Windows file system from inside WSL. Makes copies instead of using symlinks for performance and reliability reasons.
- `move_over_item <source> <destination>`: Moves source to destination with special behaviour. Meant for moving over system default config files such that they can be linked to or included from deployed files intended to take their place. Only takes effect ONCE PER SYSTEM. Creates a backup of existing content at destination before overwriting. Succeeds without effect if source does not exist. A classic example is moving the system default bashrc dotfile over to a specific destination and replacing it with your own which sources it back in from the known destination.
- `reset_move_overs`: The `move_over_item` function remembers all the items it has moved over before \(by destination\) so that the effect is only applied ONCE PER SYSTEM. This function resets that memory.
- `set_symlink <target> <link>`: Sets a symlink at link pointing to target. Creates a backup of existing content at link before overwriting. The link must be placed outside of `$REPO_PATH`.
- `prompt_choice <variable> <prompt> <default> <options>...`: Prompts the user to make a choice. The value they enter will be set into the given environment variable. The user will repeatedly be prompted until a valid choice is given. The choice may be `<default>` or any of the following `<options>`. The user will be presented with the available choices. There will be a timeout after 5 minutes of inactivity, after which the value of `<default>` is chosen automatically.

##### Important Details About Behaviour

- You should generally run `./setup.sh` as yourself and without sudo/root since the utilities make use of your home folder.
- The `./setup.sh` script will start by asking for sudo permission because it is needed by some of the provided functions and in case you use sudo in your supplied setup procedure.
- Your setup procedure script will run with its working directory set to `$REPO_PATH`, so any relative paths you use will generally resolve relative to the repository.
- Your setup procedure script will run with `set -e` and `set -o pipefail`, so your script will generally stop at the first error. This mechanism is not 100% reliable in all cases. Look into the bash documentation of those settings for more details.
- Error codes returned directly from `setup.sh` are unique so the offending line should be easy to identify.

### Guidelines for Writing Your Own Setup Procedures

You will get the most value from your procedure by making it as idempotent as possible. Erroneous situations should also be predicted, avoided, and remedied diligently. Verbose output is your friend. Your aim should be the ability to confidently and safely run your procedure repeatedly without any fear of negative side-effects or accumulation of clutter, while being presented with clear and descriptive output. Portability is generally valuable, but don't waste too much effort making things more portable than they need to be just for the sake of it.

### Philosophy

This project focuses on imperative bash scripts rather than a declarative approach like what you would see in *Docker* or *Nix*.
Though I agree that an immutable, declarative, and deployable description of your setup is ideal, it is not as ubiquitously supported as bash.
I've decided to start with bash scripts in the interest of **practicality, flexibility, portability, and accessiblity**.
I still try to approximate the benefits of a declarative approach by writing scripts that are as **idempotent** as possible within reason.
Furthermore, I've placed value in being as **verbose** as possible within reason so that the effects of actions are easily identifiable.
I also place a huge premium on **safety**, taking care to build implicit backup behaviour and graceful handling of 'unhappy paths' into the provided tools and avoiding 'shoot-yourself-in-the-foot' hazards such as `rm -rf`.

### Contribution

If there is a glaring problem or opportunity you find, **please feel free to post an issue or merge/pull request**. I won't be bothered by it. However, **please don't be offended if I completely ignore it** either.  

**This project is chiefly for my own personal benefit and not intended to grow into a public responsibility.**  

Although I am framing this as a toolkit that can be useful to anyone, that's just because doing so will naturally make my development habits more professional. For example, I wouldn't be writing this README or creating a `blank` branch if this project wasn't public.  

### Disclaimer

I cannot guarantee your privacy, data integrity, or security when using this project. You may for example accidentally delete important files when using this toolkit. Please use at your own risk and read everything before you run it, especially on an important system. I'll do my best but **I do not accept any liability**.
