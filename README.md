# OTRS Tools - Ferramentas de Diagnóstico LDAP para OTRS/Znuny

![GitHub License](https://img.shields.io/github/license/marcelofmatos/otrs-tools)
![GitHub Release](https://img.shields.io/github/v/release/marcelofmatos/otrs-tools)
![GitHub Issues](https://img.shields.io/github/issues/marcelofmatos/otrs-tools)

Coleção de scripts Perl para diagnóstico e teste de conexões LDAP no OTRS/Znuny. Essas ferramentas são essenciais para administradores que precisam validar configurações LDAP, testar autenticações e verificar grupos de usuários.

## 🚀 Instalação Rápida

### Método 1: Download automático (Recomendado)

```bash
# Download e teste imediato
curl https://raw.githubusercontent.com/marcelofmatos/otrs-tools/main/download.sh | bash
perl /opt/otrs/scripts/ldap_connection_test.pl
```

### Método 2: Instalação manual

```bash
# Clone do repositório
git clone https://github.com/marcelofmatos/otrs-tools.git
cd otrs-tools

# Instalar no OTRS/Znuny
sudo ./install.sh

# Ou copiar manualmente
sudo cp scripts/* /opt/otrs/scripts/
```
