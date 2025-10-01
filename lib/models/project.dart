class Project {
	final String id;
	final String title;
	final String address;
	final String status;
	final DateTime lastUpdateAt;
	final String assignedCustomerId;
	final String assignedContractorId;

	Project({
		required this.id,
		required this.title,
		required this.address,
		required this.status,
		required this.lastUpdateAt,
		required this.assignedCustomerId,
		required this.assignedContractorId,
	});
}
