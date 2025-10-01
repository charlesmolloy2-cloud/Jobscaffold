import '../models/user.dart';
import '../models/project.dart';
import '../models/update.dart';
import '../roles/role.dart';

final contractorCasey = AppUser(id: 'u1', name: 'Contractor Casey', role: UserRole.contractor);
final clientChris = AppUser(id: 'u2', name: 'Client Chris', role: UserRole.client);

final sampleProjects = [
	Project(
		id: 'p1',
		title: 'Kitchen Remodel',
		address: '123 Main St',
		status: 'active',
		lastUpdateAt: DateTime.now().subtract(const Duration(days: 1)),
		assignedCustomerId: clientChris.id,
		assignedContractorId: contractorCasey.id,
	),
	Project(
		id: 'p2',
		title: 'Bathroom Renovation',
		address: '456 Oak Ave',
		status: 'planning',
		lastUpdateAt: DateTime.now().subtract(const Duration(days: 3)),
		assignedCustomerId: clientChris.id,
		assignedContractorId: contractorCasey.id,
	),
	Project(
		id: 'p3',
		title: 'Deck Build',
		address: '789 Pine Rd',
		status: 'completed',
		lastUpdateAt: DateTime.now().subtract(const Duration(days: 10)),
		assignedCustomerId: clientChris.id,
		assignedContractorId: contractorCasey.id,
	),
];

final sampleUpdates = [
	Update(
		id: 'u1',
		projectId: 'p1',
		message: 'Demo complete',
		timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
		photos: [],
	),
	Update(
		id: 'u2',
		projectId: 'p1',
		message: 'Cabinets installed',
		timestamp: DateTime.now().subtract(const Duration(hours: 20)),
		photos: [],
	),
	Update(
		id: 'u3',
		projectId: 'p2',
		message: 'Plumbing rough-in started',
		timestamp: DateTime.now().subtract(const Duration(days: 2)),
		photos: [],
	),
	Update(
		id: 'u4',
		projectId: 'p3',
		message: 'Final inspection passed',
		timestamp: DateTime.now().subtract(const Duration(days: 9)),
		photos: [],
	),
];

void seedAppState(appState) {
	appState.setProjects(sampleProjects);
	appState.setUpdates(sampleUpdates);
}
