#!/bin/bash
set -e
apt install sudo -y
echo "🌎 [1/6] Configurando Locale e Limpando Pacotes Held..."
# Tenta resolver problemas de locale
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo apt-get update && sudo apt-get install -y locales || true
sudo locale-gen en_US.UTF-8 || true

# Tenta desmarcar pacotes held (corrigido)
sudo dpkg --get-selections | grep 'hold$' | awk '{print $1}' | while read pkg; do echo "$pkg install" | sudo dpkg --set-selections; done || true

echo "💥 [2/6] Remoção Agressiva de Pacotes PHP 7.1 Conflitantes..."
# Remove todos os pacotes PHP 7.1 e seus módulos, incluindo o problemático php-common.
sudo apt-get purge -y php7.1* php-common libapache2-mod-php* || true
sudo apt-get autoremove -y

echo "💾 [3/6] Adicionando Repositório PHP 7.1 (Ondřej Sury)..."
# Adiciona as ferramentas necessárias para PPA e o próprio PPA do Ondřej
sudo apt-get update && sudo apt-get install -y ca-certificates apt-transport-https lsb-release curl wget gnupg2
curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/deb.sury.org-php.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
sudo apt-get update

echo "📦 [4/6] Instalando Apache2, PHP 7.1 e Extensões Necessárias..."
# Instala o Apache, ferramentas úteis e PHP 7.1 com as extensões comuns para CI3/Projetos legados.
sudo apt-get install -y \
  apache2 \
  git curl vim nano zip unzip wget composer \
  php7.1 \
  php7.1-cli \
  libapache2-mod-php7.1 \
  php7.1-mysql \
  php7.1-mbstring \
  php7.1-curl \
  php7.1-gd \
  php7.1-xml \
  php7.1-zip \
  php7.1-intl \
  php7.1-bcmath \
  php7.1-readline \
  php7.1-mcrypt \
  php7.1-xdebug

# Define o PHP 7.1 como a versão padrão
sudo update-alternatives --set php /usr/bin/php7.1 || true

echo "⚙️ [5/6] Configurando Apache e Permissões..."
# Cria o diretório de trabalho, que estava faltando
sudo mkdir -p /workspaces/www

# O Apache roda como www-data, então damos as permissões ao root no grupo www-data.
sudo chown -R root:www-data /workspaces/www
sudo chmod -R 775 /workspaces/www

# Configura o Apache para rodar como www-data (padrão e mais estável)
sudo sed -i 's/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=www-data/' /etc/apache2/envvars
sudo sed -i 's/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=www-data/' /etc/apache2/envvars

# Habilitar módulos
sudo a2enmod rewrite
sudo a2enmod php7.1 || true 

# Configuração do VirtualHost para /workspaces
sudo tee /etc/apache2/sites-available/workspaces.conf > /dev/null <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /workspaces/www

    <Directory /workspaces/www>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Desabilitar site default e habilitar workspaces
sudo a2dissite 000-default || true
sudo a2ensite workspaces

# Configurações PHP ini de desenvolvimento
sudo mkdir -p /etc/php/7.1/apache2/conf.d
sudo tee /etc/php/7.1/apache2/conf.d/99-development.ini > /dev/null <<'EOF'
; Desenvolvimento PHP 7.1
display_errors = On
error_reporting = E_ALL
log_errors = On
max_execution_time = 300
memory_limit = 256M
upload_max_filesize = 50M
post_max_size = 50M
date.timezone = America/Fortaleza

; Configurações comuns (compatíveis com CodeIgniter 3)
short_open_tag = On
allow_url_fopen = On
EOF

echo "📄 [6/6] Criando Scripts de Controle e Index de Teste..."
# Script de controle do Apache
sudo tee /usr/local/bin/apache-control > /dev/null <<'EOF'
#!/bin/bash
case "$1" in
  start)    echo "🚀 Iniciando Apache..."; sudo service apache2 start; echo "✅ Acesse: http://localhost";;
  stop)     echo "🛑 Parando Apache...";    sudo service apache2 stop;  echo "✅ Apache parado!";;
  restart) echo "🔄 Reiniciando Apache..."; sudo service apache2 restart; echo "✅ Apache reiniciado!";;
  status)  sudo service apache2 status;;
  logs)    echo "📋 Logs do Apache (Ctrl+C para sair):"; sudo tail -f /var/log/apache2/error.log;;
  *)        echo "Uso: apache-control {start|stop|restart|status|logs}";;
esac
EOF
sudo chmod +x /usr/local/bin/apache-control

# Adiciona aliases ao bashrc do root
sudo tee /root/.bashrc > /dev/null <<'EOF'
# PHP & Apache aliases
alias php-version='php --version'
alias apache-start='apache-control start'
alias apache-stop='apache-control stop'
alias apache-restart='apache-control restart'
alias apache-logs='apache-control logs'

# Development aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF

# Iniciar Apache (Carregará a nova configuração www-data)
sudo service apache2 start

echo ""
echo "🎉 ================================================="
echo "✅ Ambiente de Desenvolvimento FINALIZADO com Sucesso!"
echo "✅ Apache $(apache2 -v | head -1) está rodando como www-data."
echo "✅ PHP 7.1 e mcrypt instalados do repositório Ondřej."
echo "🎉 ================================================="
echo ""
echo "📁 Diretório do projeto: /workspaces"
echo "🌐 URL de acesso: http://localhost"
