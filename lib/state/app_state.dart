import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/update.dart';

class AppState extends ChangeNotifier {
	void signInAs(AppUser user) {
		currentUser = user;
		notifyListeners();
	}
	AppUser? currentUser;
	List<Project> activeProjects = [];
	List<Update> updates = [];

	void signOut() {
		currentUser = null;
		notifyListeners();
	}

	void setProjects(List<Project> projects) {
		activeProjects = projects;
		notifyListeners();
	}

	void setUpdates(List<Update> newUpdates) {
		updates = newUpdates;
		notifyListeners();
	}
}
