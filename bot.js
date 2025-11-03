const https = require('https');
const http = require('http');

// ============================================
// CONFIGURACIÓN
// ============================================
const CONFIG = {
  WEBHOOK_URL: 'https://discordapp.com/api/webhooks/1434599533144178700/Px8kcPHvxS1tJmDiw3rEpQ_FurDkhipBUuuwOhWm91KEs7M6iKxuDd0Npe1uCEECm33i',
  GROUP_ID: '35815907',
  CHECK_INTERVAL: 5 * 60 * 1000, // 5 minutos en milisegundos
  PORT: process.env.PORT || 3000 // Para mantener el servicio activo en plataformas cloud
};

// Almacenar IDs de posts ya procesados
let processedPosts = new Set();

// ============================================
// FUNCIONES AUXILIARES HTTP
// ============================================

/**
 * Realiza una petición HTTP GET
 */
function httpGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    }, (res) => {
      let data = '';
      
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(data);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

/**
 * Realiza una petición HTTP POST
 */
function httpPost(url, data) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const postData = JSON.stringify(data);
    
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', chunk => responseData += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(responseData);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// ============================================
// FUNCIONES DE ROBLOX API
// ============================================

/**
 * Obtiene los posts del foro del grupo
 */
async function getGroupWallPosts(groupId) {
  try {
    const url = `https://groups.roblox.com/v2/groups/${groupId}/wall/posts?sortOrder=Desc&limit=10`;
    const response = await httpGet(url);
    const data = JSON.parse(response);
    return data.data || [];
  } catch (error) {
    console.error('Error obteniendo posts del grupo:', error.message);
    return [];
  }
}

/**
 * Obtiene información del usuario
 */
async function getUserInfo(userId) {
  try {
    const url = `https://users.roblox.com/v1/users/${userId}`;
    const response = await httpGet(url);
    return JSON.parse(response);
  } catch (error) {
    console.error('Error obteniendo info del usuario:', error.message);
    return { displayName: 'Usuario Desconocido', name: 'Unknown' };
  }
}

// ============================================
// FUNCIONES DE DISCORD
// ============================================

/**
 * Envía un mensaje al webhook de Discord
 */
async function sendToDiscord(post, userInfo) {
  const embed = {
    title: '📢 Nuevo mensaje en el foro del grupo',
    description: post.body.length > 2000 
      ? post.body.substring(0, 1997) + '...' 
      : post.body,
    color: 0x00D9FF, // Color azul de Roblox
    fields: [
      {
        name: '👤 Autor',
        value: `${userInfo.displayName} (@${userInfo.name})`,
        inline: true
      },
      {
        name: '🆔 ID del Post',
        value: post.id.toString(),
        inline: true
      }
    ],
    footer: {
      text: 'Roblox Group Forum Monitor'
    },
    timestamp: post.created
  };

  // Agregar enlace al grupo
  if (post.poster) {
    embed.author = {
      name: userInfo.displayName,
      url: `https://www.roblox.com/users/${post.poster.user.userId}/profile`,
      icon_url: `https://www.roblox.com/headshot-thumbnail/image?userId=${post.poster.user.userId}&width=150&height=150&format=png`
    };
  }

  const payload = {
    embeds: [embed],
    username: 'Roblox Forum Bot',
    avatar_url: 'https://images.rbxcdn.com/c69b74f49c785400682e1e8670d4e160'
  };

  try {
    await httpPost(CONFIG.WEBHOOK_URL, payload);
    console.log(`✅ Notificación enviada para el post ${post.id}`);
  } catch (error) {
    console.error('❌ Error enviando a Discord:', error.message);
  }
}

/**
 * Envía un mensaje de inicio al Discord
 */
async function sendStartupMessage() {
  const payload = {
    embeds: [{
      title: '🤖 Bot Iniciado',
      description: `Monitoreando el foro del grupo ${CONFIG.GROUP_ID}`,
      color: 0x00FF00,
      fields: [
        {
          name: '⏱️ Intervalo de verificación',
          value: `${CONFIG.CHECK_INTERVAL / 60000} minutos`,
          inline: true
        },
        {
          name: '📅 Fecha de inicio',
          value: new Date().toLocaleString('es-ES'),
          inline: true
        }
      ],
      footer: {
        text: 'Bot activo y funcionando'
      },
      timestamp: new Date().toISOString()
    }],
    username: 'Roblox Forum Bot'
  };

  try {
    await httpPost(CONFIG.WEBHOOK_URL, payload);
    console.log('🚀 Mensaje de inicio enviado a Discord');
  } catch (error) {
    console.error('Error enviando mensaje de inicio:', error.message);
  }
}

// ============================================
// LÓGICA PRINCIPAL
// ============================================

/**
 * Verifica nuevos posts y envía notificaciones
 */
async function checkForNewPosts() {
  console.log(`🔍 Verificando nuevos posts... [${new Date().toLocaleTimeString('es-ES')}]`);
  
  try {
    const posts = await getGroupWallPosts(CONFIG.GROUP_ID);
    
    if (posts.length === 0) {
      console.log('⚠️ No se encontraron posts');
      return;
    }

    // Procesar posts en orden inverso (más antiguos primero)
    const newPosts = posts.reverse().filter(post => !processedPosts.has(post.id));
    
    if (newPosts.length === 0) {
      console.log('✓ No hay posts nuevos');
      return;
    }

    console.log(`📝 Encontrados ${newPosts.length} posts nuevos`);

    for (const post of newPosts) {
      // Obtener información del usuario
      const userInfo = await getUserInfo(post.poster.user.userId);
      
      // Enviar a Discord
      await sendToDiscord(post, userInfo);
      
      // Marcar como procesado
      processedPosts.add(post.id);
      
      // Pequeña pausa entre notificaciones para evitar rate limiting
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Limitar el tamaño del Set para evitar uso excesivo de memoria
    if (processedPosts.size > 1000) {
      const postsArray = Array.from(processedPosts);
      processedPosts = new Set(postsArray.slice(-500));
    }

  } catch (error) {
    console.error('❌ Error en checkForNewPosts:', error.message);
  }
}

/**
 * Inicializa el bot
 */
async function initialize() {
  console.log('═══════════════════════════════════════════════════');
  console.log('🤖 Bot de Notificaciones del Foro de Roblox');
  console.log('═══════════════════════════════════════════════════');
  console.log(`📋 Grupo ID: ${CONFIG.GROUP_ID}`);
  console.log(`⏱️  Intervalo: ${CONFIG.CHECK_INTERVAL / 60000} minutos`);
  console.log('═══════════════════════════════════════════════════\n');

  // Enviar mensaje de inicio a Discord
  await sendStartupMessage();

  // Primera verificación para cargar posts existentes sin notificar
  console.log('📥 Cargando posts existentes...');
  const initialPosts = await getGroupWallPosts(CONFIG.GROUP_ID);
  initialPosts.forEach(post => processedPosts.add(post.id));
  console.log(`✓ ${processedPosts.size} posts cargados en memoria\n`);

  // Iniciar verificación periódica
  checkForNewPosts();
  setInterval(checkForNewPosts, CONFIG.CHECK_INTERVAL);

  console.log('✅ Bot iniciado correctamente\n');
}

// ============================================
// SERVIDOR HTTP (PARA MANTENER VIVO EN CLOUD)
// ============================================

/**
 * Crea un servidor HTTP simple para servicios cloud
 */
function createKeepAliveServer() {
  const server = http.createServer((req, res) => {
    if (req.url === '/') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'active',
        uptime: process.uptime(),
        processedPosts: processedPosts.size,
        lastCheck: new Date().toISOString()
      }));
    } else if (req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('OK');
    } else {
      res.writeHead(404);
      res.end('Not Found');
    }
  });

  server.listen(CONFIG.PORT, () => {
    console.log(`🌐 Servidor HTTP activo en puerto ${CONFIG.PORT}`);
  });
}

// ============================================
// MANEJO DE ERRORES Y CIERRE
// ============================================

process.on('uncaughtException', (error) => {
  console.error('💥 Error no capturado:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Promesa rechazada no manejada:', reason);
});

process.on('SIGINT', () => {
  console.log('\n👋 Cerrando bot...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n👋 Cerrando bot...');
  process.exit(0);
});

// ============================================
// INICIO DEL BOT
// ============================================

createKeepAliveServer();
initialize();
