const { ModernAuth } = require('../modern-auth');

(async () => {
  try {
    const auth = new ModernAuth();
    await auth.authenticate();
    console.log('YouTube OAuth completed.');
    process.exit(0);
  } catch (error) {
    console.error(error && error.message ? error.message : error);
    process.exit(1);
  }
})();
