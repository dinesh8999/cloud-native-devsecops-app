const app = require('./app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`[INFO] Server running on port ${PORT}`);
  console.log(`[INFO] Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`[INFO] Ready to accept incoming ALB traffic.`);
});

// Graceful shutdown handling for container termination
const gracefulShutdown = (signal) => {
  console.log(`[INFO] Received ${signal}. Shutting down gracefully...`);
  server.close(() => {
    console.log('[INFO] Closed out remaining active HTTP connections.');
    process.exit(0);
  });

  // Force shutdown after 10s if connections linger
  setTimeout(() => {
    console.error('[ERROR] Could not close connections in time, forcing shutdown');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
