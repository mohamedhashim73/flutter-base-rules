import 'package:base/model/base/pagination_model.dart';

abstract interface class LoadableResponse<T> {
  T? get data;
}

abstract interface class PaginatedResponse<T, Self>
    implements LoadableResponse<T> {
  PaginationModel? get pagination;

  Self copyWithPagination({
    required List<dynamic> data,
    required PaginationModel? pagination,
  });
}

class PaginationParams {
  final int? page;
  final int? perPage;
  final String? search;

  const PaginationParams({
    this.page,
    this.perPage,
    this.search,
  });

  Map<String, String> toMap() {
    return {
      if (page != null) 'page': page.toString(),
      if (perPage != null) 'per_page': perPage.toString(),
      if (search?.isNotEmpty == true) 'search': search!,
    };
  }

  PaginationParams copyWith({
    int? page,
    int? perPage,
    String? search,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      search: search ?? this.search,
    );
  }
}

class ListData<T> implements LoadableResponse<List<T>> {
  @override
  final List<T>? data;

  const ListData(this.data);
}

class SingleData<T> implements LoadableResponse<T> {
  @override
  final T? data;

  const SingleData(this.data);
}