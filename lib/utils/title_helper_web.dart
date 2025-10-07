// Web-only implementation to set the document title safely.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void setDocumentTitle(String title) {
  try {
    html.document.title = title;
  } catch (_) {
    // ignore errors (e.g., during tests)
  }
}
