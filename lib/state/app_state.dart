import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
	bool reduceMotion = false;

	// Debug-only developer bypass to skip real auth guards.
	// When set, dashboards won't redirect to sign-in.
	// Accepted values: 'contractor' or 'client'. Not persisted.
	String? devBypassRole;

	void enableDevBypass(String role) {
		devBypassRole = role;
		notifyListeners();
	}

	void disableDevBypass() {
		devBypassRole = null;
		notifyListeners();
	}

	void setReduceMotion(bool value) {
		reduceMotion = value;
		notifyListeners();
		savePreferences();
	}

	static const _prefReduceMotionKey = 'reduce_motion';

	Future<void> loadPreferences() async {
		final prefs = await SharedPreferences.getInstance();
		reduceMotion = prefs.getBool(_prefReduceMotionKey) ?? false;
		notifyListeners();
	}

	Future<void> savePreferences() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(_prefReduceMotionKey, reduceMotion);
	}

	void signOut() {
		currentUser = null;
		notifyListeners();
	}

	void setProjects(List<Project> projects) {
		activeProjects = projects;
		notifyListeners();
	}

	void addProject(Project project) {
		activeProjects = [project, ...activeProjects];
		notifyListeners();
	}

	void updateProject(Project project) {
		final i = activeProjects.indexWhere((p) => p.id == project.id);
		if (i != -1) {
			activeProjects[i] = project;
			notifyListeners();
		}
	}

	void removeProject(String projectId) {
		activeProjects = activeProjects.where((p) => p.id != projectId).toList();
		notifyListeners();
	}

	void setUpdates(List<Update> newUpdates) {
		updates = newUpdates;
		notifyListeners();
	}
}
