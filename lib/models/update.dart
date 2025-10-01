class Update {
	final String id;
	final String projectId;
	final String message;
	final DateTime timestamp;
	final List<String>? photos;

	Update({
		required this.id,
		required this.projectId,
		required this.message,
		required this.timestamp,
		this.photos,
	});
}
