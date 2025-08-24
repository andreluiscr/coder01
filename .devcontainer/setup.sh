#!/bin/bash

echo "🐘 Configurando PHP 5.6 + Apache2 + CodeIgniter 3 para Coder..."

# Atualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Adicionar repositório do PHP 5.6 (compatível com Ubuntu 20.04)
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

echo "📦 Instalando Apache2..."
# Instalar Apache2
sudo apt-get install -y apache2

echo "🐘 Instalando PHP 5.6..."
# Instalar PHP 5.6 e extensões necessárias para CodeIgniter 3
sudo apt-get install -y \
    php5.6 \
    php5.6-cli \
    php5.6-apache2 \
    php5.6-mysql \
    php5.6-mysqli \
    php5.6-pdo \
    php5.6-mbstring \
    php5.6-curl \
    php5.6-gd \
    php5.6-xml \
    php5.6-zip \
    php5.6-json \
    php5.6-mcrypt \
    php5.6-intl \
    libapache2-mod-php5.6

# Definir PHP 5.6 como versão padrão
sudo update-alternatives --set php /usr/bin/php5.6

# Instalar ferramentas úteis
sudo apt-get install -y \
    git \
    curl \
    vim \
    nano \
    zip \
    unzip \
    wget \
    composer

echo "⚙️ Configurando Apache..."

# Habilitar mod_rewrite (necessário para .htaccess do CodeIgniter)
sudo a2enmod rewrite
sudo a2enmod php5.6

# Configurar Apache para usar o workspace como DocumentRoot
sudo tee /etc/apache2/sites-available/workspace.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /workspace
    
    <Directory /workspace>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html
    </Directory>
    
    # Configurações específicas para CodeIgniter
    <Directory /workspace>
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\.php$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.php [L]
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Desabilitar site padrão e habilitar o workspace
sudo a2dissite 000-default
sudo a2ensite workspace

# Configurar PHP 5.6 para desenvolvimento
sudo tee /etc/php/5.6/apache2/conf.d/99-development.ini > /dev/null <<EOF
; Configurações de desenvolvimento PHP 5.6
display_errors = On
error_reporting = E_ALL
log_errors = On
max_execution_time = 300
memory_limit = 256M
upload_max_filesize = 50M
post_max_size = 50M
date.timezone = America/Sao_Paulo

; Configurações para CodeIgniter 3
short_open_tag = On
allow_url_fopen = On
EOF

# Configurar permissões corretas
sudo chown -R vscode:www-data /workspace
sudo chmod -R 775 /workspace

# Configurar Apache para rodar como usuário correto
sudo sed -i 's/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=vscode/' /etc/apache2/envvars
sudo sed -i 's/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=vscode/' /etc/apache2/envvars

# Criar script para gerenciar Apache
sudo tee /usr/local/bin/apache-control > /dev/null <<'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "🚀 Iniciando Apache..."
        sudo service apache2 start
        echo "✅ Apache iniciado! Acesse: http://localhost"
        ;;
    stop)
        echo "🛑 Parando Apache..."
        sudo service apache2 stop
        echo "✅ Apache parado!"
        ;;
    restart)
        echo "🔄 Reiniciando Apache..."
        sudo service apache2 restart
        echo "✅ Apache reiniciado!"
        ;;
    status)
        sudo service apache2 status
        ;;
    logs)
        echo "📋 Logs do Apache (Ctrl+C para sair):"
        sudo tail -f /var/log/apache2/error.log
        ;;
    *)
        echo "Uso: apache-control {start|stop|restart|status|logs}"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/apache-control

# Criar script para criar projeto CodeIgniter 3
cat > /home/vscode/create-codeigniter-project.sh << 'EOF'
#!/bin/bash

echo "🔥 Configurando projeto CodeIgniter 3..."

# Verificar se já existe um projeto
if [ -f "/workspace/index.php" ]; then
    echo "⚠️  Já existe um projeto no workspace!"
    echo "Deseja sobrescrever? (y/N):"
    read overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "❌ Operação cancelada!"
        exit 1
    fi
fi

cd /workspace

# Baixar CodeIgniter 3 (última versão)
echo "📥 Baixando CodeIgniter 3..."
wget -q https://github.com/bcit-ci/CodeIgniter/archive/refs/tags/3.1.13.zip -O codeigniter.zip
unzip -q codeigniter.zip
mv CodeIgniter-3.1.13/* .
mv CodeIgniter-3.1.13/.* . 2>/dev/null || true
rm -rf CodeIgniter-3.1.13
rm codeigniter.zip

# Configurar permissões
chmod -R 755 .
chmod -R 777 application/logs
chmod -R 777 application/cache

# Criar .htaccess otimizado para CodeIgniter 3
cat > .htaccess << 'HTACCESS'
RewriteEngine On

# Remove index.php from URLs
RewriteCond %{THE_REQUEST} /index\.php/([^\s\?]*) [NC]
RewriteRule ^ /%1 [R=302,L]

# Routes all requests to index.php if file/directory doesn't exist
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php/$1 [L]

# Security: Deny access to system folder
RewriteCond %{REQUEST_URI} ^system.*
RewriteRule ^(.*)$ /index.php?/$1 [L]

# Security: Deny access to application folder
RewriteCond %{REQUEST_URI} ^application.*
RewriteRule ^(.*)$ /index.php?/$1 [L]

# Prevent access to .htaccess
<Files ".htaccess">
Order allow,deny
Deny from all
</Files>

# Cache control for static assets
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType image/ico "access plus 1 month"
</IfModule>

# Gzip compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>
HTACCESS

# Configurar config.php básico
sed -i "s|\$config\['base_url'\] = '';|\$config\['base_url'\] = 'http://localhost/';|g" application/config/config.php
sed -i "s|\$config\['index_page'\] = 'index.php';|\$config\['index_page'\] = '';|g" application/config/config.php

# Configurar database.php com exemplo
cat > application/config/database.php << 'DBCONFIG'
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

$active_group = 'default';
$query_builder = TRUE;

$db['default'] = array(
    'dsn'   => '',
    'hostname' => 'localhost',
    'username' => 'root',
    'password' => '',
    'database' => 'codeigniter_db',
    'dbdriver' => 'mysqli',
    'dbprefix' => '',
    'pconnect' => FALSE,
    'db_debug' => (ENVIRONMENT !== 'production'),
    'cache_on' => FALSE,
    'cachedir' => '',
    'char_set' => 'utf8',
    'dbcollat' => 'utf8_general_ci',
    'swap_pre' => '',
    'encrypt' => FALSE,
    'compress' => FALSE,
    'stricton' => FALSE,
    'failover' => array(),
    'save_queries' => TRUE
);
DBCONFIG

# Criar controller de exemplo
mkdir -p application/controllers
cat > application/controllers/Welcome.php << 'WELCOME'
<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Welcome extends CI_Controller {

    public function __construct() {
        parent::__construct();
    }

    public function index() {
        $data = array(
            'title' => 'CodeIgniter 3 + Coder',
            'message' => 'Ambiente de desenvolvimento configurado com sucesso!',
            'php_version' => phpversion(),
            'ci_version' => CI_VERSION
        );
        
        $this->load->view('welcome', $data);
    }
    
    public function info() {
        phpinfo();
    }
}
WELCOME

# Criar view de exemplo
mkdir -p application/views
cat > application/views/welcome.php << 'VIEW'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $title; ?></title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            text-align: center; 
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 2.5em; margin-bottom: 20px; }
        .info { 
            background: rgba(255,255,255,0.1); 
            padding: 20px; 
            border-radius: 5px; 
            margin: 20px 0; 
        }
        .info span { font-weight: bold; color: #FFD700; }
        a { color: #FFD700; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .footer { margin-top: 40px; font-size: 0.9em; opacity: 0.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔥 <?php echo $title; ?></h1>
        <p style="font-size: 1.2em;"><?php echo $message; ?></p>
        
        <div class="info">
            <p><span>PHP Version:</span> <?php echo $php_version; ?></p>
            <p><span>CodeIgniter Version:</span> <?php echo $ci_version; ?></p>
            <p><span>Environment:</span> <?php echo ENVIRONMENT; ?></p>
        </div>
        
        <p>
            <a href="<?php echo base_url('index.php/welcome/info'); ?>">Ver PHP Info</a> |
            <a href="<?php echo base_url('application/'); ?>">Application Folder</a>
        </p>
        
        <div class="footer">
            <p>🚀 Desenvolvendo com CodeIgniter 3 no Coder</p>
        </div>
    </div>
</body>
</html>
VIEW

echo ""
echo "🎉 =================================="
echo "✅ CodeIgniter 3 configurado!"
echo "🎉 =================================="
echo ""
echo "🌐 Acesse: http://localhost"
echo "📁 Projeto: /workspace"
echo ""
echo "📋 Estrutura criada:"
echo "   - .htaccess (URL rewriting)"
echo "   - application/config/config.php"
echo "   - application/config/database.php"
echo "   - application/controllers/Welcome.php"
echo "   - application/views/welcome.php"
echo ""
EOF

chmod +x /home/vscode/create-codeigniter-project.sh

# Adicionar aliases úteis ao .bashrc
cat >> /home/vscode/.bashrc << 'EOF'

# PHP & Apache aliases
alias php-version='php --version'
alias apache-start='apache-control start'
alias apache-stop='apache-control stop'
alias apache-restart='apache-control restart'
alias apache-logs='apache-control logs'
alias ci-create='~/create-codeigniter-project.sh'

# Development aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

EOF

# Iniciar Apache automaticamente
sudo service apache2 start

echo ""
echo "🎉 ================================================="
echo "✅ PHP 5.6 + Apache2 + CodeIgniter 3 configurado!"
echo "🎉 ================================================="
echo ""
echo "🚀 Para criar projeto CodeIgniter:"
echo "   ~/create-codeigniter-project.sh"
echo ""
echo "🔧 Comandos úteis:"
echo "   apache-start    - Iniciar Apache"
echo "   apache-stop     - Parar Apache"
echo "   apache-restart  - Reiniciar Apache"
echo "   apache-logs     - Ver logs do Apache"
echo "   php-version     - Versão do PHP"
echo ""
echo "📁 Diretório do projeto: /workspace"
echo "🌐 URL de acesso: http://localhost"
echo ""
echo "🔧 Configurações:"
echo "   - PHP $(php --version | head -1)"
echo "   - Apache $(apache2 -v | head -1)"
echo "   - mod_rewrite habilitado"
echo "   - Todas extensões PHP necessárias"
echo "   - Permissões configuradas"
echo ""
echo "🎯 Próximo passo: Execute o comando ci-create"
echo ""
