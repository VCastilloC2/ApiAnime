/// Respuesta tipada: el dato ya parseado + metadatos útiles de la API FastAPI.
class ApiResponse<T> {
  final T data;

  /// Cabecera `X-Total-Count` (paginación).
  final int? totalCount;

  /// Cabecera `X-Process-Time-ms` (tiempo que tardó el servidor).
  final double? serverTimeMs;

  /// Tiempo total ida y vuelta medido en el cliente.
  final int roundTripMs;

  const ApiResponse({
    required this.data,
    this.totalCount,
    this.serverTimeMs,
    this.roundTripMs = 0,
  });
}
