/**
 * Generates a lightweight summary of a version for instant rendering.
 */
exports.getLatestVersionSummary = (version) => {
  if (!version) return null;
  return {
    versionNumber: version.versionNumber,
    status: version.status,
    createdAt: version.createdAt,
    createdBy: version.createdBy,
    noteCount: version.notes ? version.notes.length : 0,
    notesPreview: version.notes ? version.notes.map(n => ({
      type: n.type,
      title: n.title,
      // Lightweight preview of content
      contentPreview: n.content ? (n.content.length > 150 ? n.content.substring(0, 150) + '...' : n.content) : '',
      metadata: n.metadata,
      id: n._id
    })) : []
  };
};
