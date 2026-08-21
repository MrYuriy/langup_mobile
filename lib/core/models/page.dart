/// Matches the backend generic `Page[T]` schema.
class Page<T> {
  const Page({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    return Page(
      items: [
        for (final e in (json['items'] as List))
          item((e as Map).cast<String, dynamic>()),
      ],
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}
