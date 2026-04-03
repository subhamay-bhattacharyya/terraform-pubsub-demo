module.exports = async (pluginConfig, context) => {
  const { commits, nextRelease, logger } = context;
  try {
    logger.log('📝 Generating release notes...');
    const notes = commits.map(commit => `- ${commit.message}`).join('\n');
    const releaseNotes = `## ${nextRelease.version}\n\n${notes}`;
    logger.log('✔ Release notes generated.');
    return releaseNotes;
  } catch (error) {
    logger.error('❌ Failed to generate release notes.');
    throw error;
  }
};