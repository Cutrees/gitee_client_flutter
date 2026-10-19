import '../models/repoV3.dart';

class ExplorationPaging {
  ExplorationPaging(this.fetch);

  final Future<List<RepoV3>> Function(int page, bool refresh) fetch;
  int _startPage = 1;
  int _lastPage = 0;
  int _generation = 0;

  Future<bool> load(int page, List<RepoV3> items, bool refresh) async {
    final generation = refresh ? ++_generation : _generation;
    var remotePage = refresh ? _lastPage + 1 : _startPage + page - 1;
    var data = await fetch(remotePage, refresh);
    if (generation != _generation) return false;
    if (refresh && data.isEmpty && remotePage > 1) {
      remotePage = 1;
      data = await fetch(remotePage, true);
      if (generation != _generation) return false;
    }
    final ids = items.map((item) => item.id).whereType<num>().toSet();
    var added = 0;
    for (final repo in data) {
      if (repo.id != null && ids.add(repo.id!)) {
        items.add(repo);
        added++;
      }
    }
    if (refresh) _startPage = remotePage;
    if (data.isNotEmpty) _lastPage = remotePage;
    return added > 0;
  }
}
