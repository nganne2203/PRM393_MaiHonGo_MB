class ContentResult<T> {
  final T data;
  final bool isOffline;
  final String? errorMessage;

  const ContentResult({
    required this.data,
    this.isOffline = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
