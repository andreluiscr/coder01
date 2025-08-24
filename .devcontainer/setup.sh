#!/bin/bash

echo "🌟 Configurando ambiente Expo para React Native no Coder..."

# Atualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Instalar dependências essenciais
sudo apt-get install -y \
    curl \
    git \
    unzip \
    zip \
    wget \
    python3 \
    python3-pip \
    build-essential

echo "📦 Instalando ferramentas Expo e React Native..."

# Instalar ferramentas globais do Node.js otimizadas para Expo
npm install -g \
    @expo/cli@latest \
    expo-cli \
    eas-cli \
    @react-native-community/cli \
    yarn \
    typescript \
    @types/react \
    @types/react-native \
    prettier \
    eslint

echo "✅ Ferramentas instaladas com sucesso!"

# Configurar variáveis de ambiente para Expo
cat >> /home/vscode/.bashrc << 'EOF'

# Expo Environment Variables
export EXPO_DEVTOOLS_LISTEN_ADDRESS=0.0.0.0
export REACT_NATIVE_PACKAGER_HOSTNAME=0.0.0.0
export EXPO_USE_LOCAL_CLI=1

# Aliases úteis para Expo
alias expo-start='npx expo start'
alias expo-web='npx expo start --web'
alias expo-tunnel='npx expo start --tunnel'
alias expo-clear='npx expo start --clear'
alias expo-build='npx expo build'
alias eas-build='npx eas build'
alias eas-submit='npx eas submit'

# Aliases para desenvolvimento
alias dev='npx expo start --web'
alias dev-tunnel='npx expo start --tunnel'
alias dev-clear='npx expo start --web --clear'

EOF

# Criar script para novo projeto Expo
cat > /home/vscode/create-expo-app.sh << 'EOF'
#!/bin/bash

echo "🌟 Criando novo projeto Expo..."
echo ""

# Perguntar nome do projeto
echo "📝 Digite o nome do projeto:"
read project_name

if [ -z "$project_name" ]; then
    echo "❌ Nome do projeto é obrigatório!"
    exit 1
fi

echo ""
echo "🎯 Escolha o template:"
echo "1) Blank (JavaScript)"
echo "2) Blank (TypeScript) - Recomendado"
echo "3) Navigation (TypeScript)"
echo "4) Tabs (TypeScript)"
echo ""
echo "Digite sua escolha (1-4):"
read template_choice

case $template_choice in
    1)
        template="blank"
        ;;
    2)
        template="blank-typescript"
        ;;
    3)
        template="--template @expo/template-navigation-typescript"
        ;;
    4)
        template="--template @expo/template-tabs-typescript"
        ;;
    *)
        echo "Usando template padrão: blank-typescript"
        template="blank-typescript"
        ;;
esac

echo ""
echo "📱 Criando projeto '$project_name' com template '$template'..."

if [[ $template == *"--template"* ]]; then
    npx create-expo-app "$project_name" $template
else
    npx create-expo-app "$project_name" --template "$template"
fi

cd "$project_name"

# Adicionar scripts úteis ao package.json
echo "⚙️ Configurando scripts personalizados..."

npx json -I -f package.json -e "
this.scripts.dev = 'expo start --web';
this.scripts['dev:tunnel'] = 'expo start --tunnel';
this.scripts['dev:clear'] = 'expo start --web --clear';
this.scripts.build = 'expo export';
this.scripts['build:web'] = 'expo export --platform web';
this.scripts.preview = 'npx serve dist';
"

# Instalar dependências adicionais úteis
echo "📦 Instalando dependências adicionais..."
npx expo install expo-constants expo-linking expo-status-bar

echo ""
echo "🎉 ================================================"
echo "✅ Projeto '$project_name' criado com sucesso!"
echo "🎉 ================================================"
echo ""
echo "📋 Para começar o desenvolvimento:"
echo "   cd $project_name"
echo "   npm run dev          # Inicia no navegador"
echo "   npm run dev:tunnel   # Para testar no celular"
echo ""
echo "🌐 URLs importantes:"
echo "   - Web: http://localhost:19006"
echo "   - DevTools: http://localhost:19000"
echo ""
echo "📱 Para testar no celular:"
echo "   1. Instale o app 'Expo Go'"
echo "   2. Execute: npm run dev:tunnel"
echo "   3. Escaneie o QR code"
echo ""
EOF

chmod +x /home/vscode/create-expo-app.sh

# Criar template personalizado para App.tsx
mkdir -p /home/vscode/templates
cat > /home/vscode/templates/ExpoApp.tsx << 'EOF'
import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, Platform } from 'react-native';

export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>🚀 Expo + Coder</Text>
      <Text style={styles.subtitle}>
        Ambiente de desenvolvimento configurado!
      </Text>
      <Text style={styles.platform}>
        Plataforma: {Platform.OS === 'web' ? '🌐 Web' : '📱 Mobile'}
      </Text>
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    color: '#666',
    marginBottom: 20,
  },
  platform: {
    fontSize: 14,
    color: '#888',
    fontStyle: 'italic',
  },
});
EOF

# Criar configuração do Prettier
cat > /home/vscode/.prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false
}
EOF

# Criar script para executar comandos úteis
cat > /home/vscode/expo-commands.sh << 'EOF'
#!/bin/bash

echo "🌟 Comandos úteis do Expo:"
echo ""
echo "📋 Comandos básicos:"
echo "   expo-web           - Iniciar no navegador"
echo "   expo-tunnel        - Iniciar com tunnel (para celular)"
echo "   expo-clear         - Iniciar limpando cache"
echo ""
echo "📱 Para projetos:"
echo "   ~/create-expo-app.sh - Criar novo projeto"
echo ""
echo "🔧 Debug e Build:"
echo "   expo doctor        - Verificar problemas"
echo "   expo export        - Build para produção"
echo "   eas build          - Build nativo"
echo ""
echo "🌐 URLs padrão:"
echo "   Web: http://localhost:19006"
echo "   DevTools: http://localhost:19000"
echo ""
EOF

chmod +x /home/vscode/expo-commands.sh

# Configurar Git
git config --global init.defaultBranch main
git config --global core.autocrlf false

# Limpar cache
npm cache clean --force

echo ""
echo "🎉 ================================================="
echo "✅ Ambiente Expo configurado para Coder!"
echo "🎉 ================================================="
echo ""
echo "🚀 Scripts disponíveis:"
echo "   ~/create-expo-app.sh     - Criar projeto Expo"
echo "   ~/expo-commands.sh       - Ver comandos úteis"
echo ""
echo "⚡ Desenvolvimento rápido:"
echo "   1. Execute: ~/create-expo-app.sh"
echo "   2. Execute: cd MeuProjeto"
echo "   3. Execute: npm run dev"
echo "   4. Acesse: http://localhost:19006"
echo ""
echo "🔧 Ferramentas instaladas:"
echo "   - Node.js $(node -v)"
echo "   - npm $(npm -v) | yarn $(yarn -v)"
echo "   - Expo CLI $(npx expo --version)"
echo "   - EAS CLI $(npx eas --version)"
echo "   - TypeScript $(npx tsc --version)"
echo ""
echo "🌐 Portas configuradas:"
echo "   - 19006: Expo Web (principal)"
echo "   - 19000: Expo DevTools"
echo "   - 8081: Metro Bundler"
echo ""
echo "📱 Para testar no celular:"
echo "   - Instale 'Expo Go' no celular"
echo "   - Use: npm run dev:tunnel"
echo "   - Escaneie o QR code"
echo ""
echo "💡 Templates disponíveis:"
echo "   1. Blank (JavaScript/TypeScript)"
echo "   2. Navigation (com React Navigation)"
echo "   3. Tabs (com Tab Navigation)"
echo ""
echo "🚀 Pronto para desenvolver com Expo!"
echo ""
