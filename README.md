# infra-homelab
ansible scripts and another stuffs for install automation

# Generar la clave SSH

```bash
ssh-keygen -t rsa -b 4096 -f ./keys/rock5b
ssh-copy-id -i ./keys/rock5b user@server
```

# Ejecutar playbook (rock5b-setup)

```bash
ansible-playbook -i inventory rock5b-setup/main.yaml --ask-become-pass
```

# Actualizar connfiguración de nginx
```bash
ansible-playbook -i inventory nginx/update-config.yaml 
```