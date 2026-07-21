import 'package:playx/playx.dart';

class PaginationModel {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  const PaginationModel({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: asIntOr(json, 'total'),
      count: asIntOr(json, 'count'),
      perPage: asIntOr(json, 'per_page'),
      currentPage: asIntOr(json, 'current_page'),
      totalPages: asIntOr(json, 'total_pages'),
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'count': count,
        'per_page': perPage,
        'current_page': currentPage,
        'total_pages': totalPages,
      };

  PaginationModel copyWith({
    int? total,
    int? count,
    int? perPage,
    int? currentPage,
    int? totalPages,
  }) {
    return PaginationModel(
      total: total ?? this.total,
      count: count ?? this.count,
      perPage: perPage ?? this.perPage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  bool get hasNext => currentPage < totalPages;

}