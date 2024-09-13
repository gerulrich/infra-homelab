## MacOs config

# Configure git for work and personal folders

cat ~/git/.gitconfig:
```
[includeIf "gitdir:~/git/work"]
    path = ~/git/work/.gitconfig

[includeIf "gitdir:~/git/personal/"]
    path = ~/git/personal/.gitconfig
```

cat ~/git/work/.gitconfig:
```
[user]
        signingkey = <work signing key>
        name = <Name>
        email = <work email>
[commit]
        gpgsign = true
[core]
        autocrlf = input
```

cat ~/git/personal/.gitconfig:
```
[user]
        signingkey = <personal signing key>
        name = <Name>
        email = <personal email>
[commit]
        gpgsign = true
[core]
        autocrlf = input
```

# Configure ssh (github and others)

cat .ssh/config:
```
work account
Host github.com
	HostName github.com
	User git
	IdentityFile ~/ssh-keys/github_work

#gerulrich account
Host github.com-gerulrich
	HostName github.com
	User git
    IdentityFile ~/ssh-keys/github_gerulrich

Host 192.168.0.10
	HostName 192.168.0.10
	User rock
	IdentityFile ~/ssh-keys/homelab_rock5b
```

# Mac OS Setup

Antes de todo actualizar MacOs a la ultima version disponible:

## Bash
Fuente: https://merikan.com/2019/04/upgrade-to-bash-5-in-macos

Verificar version:
```
bash -version
```
Imprimir versión actual:
```
command -v bash
```
Instalar con brew:
```
brew install bash
```
Agregar bash instalado a la lista de shells de inicio de sesión disponibles:
```
sudo bash -c 'echo "$(command -v bash)" >> /etc/shells'
```
Imprimir la lista de shells disponibles:
```
cat /etc/shells
```
Actualizar perfil para usar el nuevo shell bash:
```
chsh -s $(command -v bash)
```

## Python

Fuente: https://www.freecodecamp.org/news/python-version-on-mac-update/

```
brew install pyenv
pyenv install 3.9.2 
pyenv global 3.9.2
```

Agregar en .bash_profile:
```
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH=$(pyenv root)/shims:/usr/local/bin:/usr/bin:/bin:$PATH
```

Reiniciar terminal y ejecutar:
```
python --version
```

## PowerLine (bash)

Fuente: https://www.freecodecamp.org/news/jazz-up-your-bash-terminal-a-step-by-step-guide-with-pictures-80267554cb22/

```
pip3 install powerline-status
pip3 show powerline-status
```

Ejecutar el siguiente comando para ver donde está instalado:
```
pip3 show powerline-status
```

Agregar en .bash_profile
```
# Powerline
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
source [path de instalacion/site-packages]/powerline/bindings/bash/powerline.sh
```

Descargar las fuentes desde aquí:
```
https://github.com/powerline/fonts
```
Instalar las fuentes “Meslo LG L DZ Regular for Powerline.ttf” and “Meslo LG L DZ Italic for Powerline.ttf”

Seleccionar la fuente desde iTerm2: Preferencias -> Profiles -> Text

## Powerline Git

```
pip3 install powerline-gitstatus
pip3 show powerline-gitstatus
```

Agregar el color schema en: colorschemes/shell/default.json
```
[path de instalacion]/powerline/config_files/colorschemes/shell/default.json

```

El archivo tiene que quedar similar a:
```
{
	"name": "Default color scheme for shell prompts",
	"groups": {
		"hostname": {
			"fg": "brightyellow",
			"bg": "mediumorange",
			"attrs": []
		},
		"environment": {
			"fg": "white",
			"bg": "darkestgreen",
			"attrs": []
		},
		"mode": {
			"fg": "darkestgreen",
			"bg": "brightgreen",
			"attrs": ["bold"]
		},
		"attached_clients": {
			"fg": "white",
			"bg": "darkestgreen",
			"attrs": []
		},

		"gitstatus": {
			"fg": "gray8",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_branch": {
			"fg": "gray8",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_branch_clean": {
			"fg": "green",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_branch_dirty": {
			"fg": "gray8",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_branch_detached": {
			"fg": "mediumpurple",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_tag": {
			"fg": "darkcyan",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_behind": {
			"fg": "gray10",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_ahead": {
			"fg": "gray10",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_staged": {
			"fg": "green",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_unmerged": {
			"fg": "brightred",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_changed": {
			"fg": "mediumorange",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_untracked": {
			"fg": "brightestorange",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus_stashed": {
			"fg": "darkblue",
			"bg": "gray2",
			"attrs": []
		},
		"gitstatus:divider": {
			"fg": "gray8",
			"bg": "gray2",
			"attrs": []
		}
	},
	"mode_translations": {
		"vicmd": {
			"groups": {
				"mode": {
					"fg": "darkestcyan",
					"bg": "white",
					"attrs": ["bold"]
				}
			}
		}
	}
}
```

Agregar en default.json
```
[path de instalacion]/powerline/config_files/themes/shell/default.json

```

El archivo tiene que quedar similar a:
```
{
	"segments": {
		"left": [{
				"function": "powerline.segments.shell.mode"
			},
			{
				"function": "powerline.segments.common.net.hostname",
				"priority": 10
			},
			{
				"function": "powerline.segments.common.env.user",
				"priority": 30
			},
			{
				"function": "powerline.segments.shell.cwd",
				"priority": 10
			}, {
				"function": "powerline_gitstatus.gitstatus",
				"priority": 40
			}
		],
		"right": []
	}
}
```

Reiniciar el daemon de powerline:
```
powerline-daemon —-replace
```

