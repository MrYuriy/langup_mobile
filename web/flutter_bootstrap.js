// Custom bootstrap: everything the generated one does, minus the service
// worker.
//
// Flutter's service worker is a second cache on top of the HTTP one, with its
// own idea of when a resource is stale. The backend already versions every
// asset URL per build — a deploy changes the path, so nothing can serve an old
// bundle — and a second mechanism layered on that only adds ways for the two to
// disagree. One deterministic scheme beats two clever ones.
//
// Omitting `serviceWorkerSettings` from the loader config is what disables it.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
