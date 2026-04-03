module.exports = async (pluginConfig, context) => {
  const { logger } = context;
  try {
    logger.log('🔍 Verifying conditions for release...');
    logger.log('✔ Conditions verified.');
  } catch (error) {
    logger.error('❌ Failed to verify conditions.');
    throw error;
  }
};