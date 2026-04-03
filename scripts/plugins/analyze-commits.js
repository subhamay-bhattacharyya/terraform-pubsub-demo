module.exports = async (pluginConfig, context) => {
  const { commits, logger } = context;
  logger.log('🔍 Analyzing commits...');
  try {
    for (const commit of commits) {
      logger.log(`- Commit: ${commit.message}`);
    }

    const hasFeature = commits.some(c => c.message.startsWith('feat'));
    const hasFix = commits.some(c => c.message.startsWith('fix'));

    if (hasFeature) {
      logger.log('✔ Release type: minor');
      return 'minor';
    } else if (hasFix) {
      logger.log('✔ Release type: patch');
      return 'patch';
    }

    logger.log('ℹ No release needed.');
    return null;
  } catch (error) {
    logger.error('❌ Error analyzing commits.');
    throw error;
  }
};