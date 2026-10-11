# Anime Pulse — Flutter Web + Móvil

Cliente Flutter (Clean Architecture + Riverpod + Dio + fl_chart) para la API **ApiAnimeGrafica** (FastAPI).

## Puesta en marcha

```bash
# 1) Genera las carpetas de plataforma (web/android/ios) dentro de este proyecto
flutter create . --platforms=web,android,ios --project-name anime_pulse
flutter pub get

# 2) Arranca la API (otra terminal)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 3) Ejecuta
flutter run -d chrome                                            # web
flutter run                                                      # emulador Android (usa 10.0.2.2:8000)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000  # celular físico

flutter test
```

CORS: tu API ya expone `X-Total-Count` y `X-Process-Time-ms`; en producción define `CORS_ORIGINS` con el dominio de la web.

## Endpoints consumidos

| Pantalla | Endpoint |
|---|---|
| Explorar | `GET /animes` (skip, limit, search, genre_id, sort_by, order) + `X-Total-Count`, `GET /genres` |
| Ranking | `GET /stats/top-rated` |
| Dashboard KPIs | `GET /stats/summary` |
| Donut / Radar | `GET /stats/by-genre` |
| Barras | `GET /stats/rating-distribution` |
| Dispersión + regresión, tendencia | `GET /animes?limit=200&sort_by=created_at` (cálculo en cliente) |
| Latencia en vivo | `GET /health` + cabecera `X-Process-Time-ms` |

## Capas

```
presentation  (widgets, Riverpod)  ──►  domain (entities, repository interfaces, use cases)  ◄──  data (models, datasources/Dio, repository impl)
```
`domain` no importa Flutter, Dio ni Riverpod. Los errores viajan como `Failure` tipados.

## Guía de optimización (Flutter Web y estado)

**Build y carga inicial**
- Release con renderer WASM/CanvasKit moderno: `flutter build web --release --wasm` (si algún plugin no es compatible, usa `flutter build web --release`).
- Tree shaking: viene activo en release (íconos, código muerto). Añade `--tree-shake-icons` explícito si lo desactivaste. Evita importar paquetes enteros que no uses.
- Carga diferida de módulos pesados: `import '...dashboard_screen.dart' deferred as dash;` y `await dash.loadLibrary();` antes de mostrar la pantalla → el bundle inicial no incluye fl_chart.
- Splash en `web/index.html` (logo + spinner CSS) para tapar la descarga de `main.dart.js`.
- Servidor: gzip/brotli en Nginx/Cloudflare, `Cache-Control: immutable` para assets con hash, `no-cache` para `index.html` y `flutter_service_worker.js`.

**Imágenes** (tu API hoy no tiene portadas; cuando las añadas)
- Sirve miniaturas WebP/AVIF desde la API/CDN (`?w=400`), nunca el original.
- `cached_network_image` con `memCacheWidth`, o `Image.network(cacheWidth: ...)` para decodificar al tamaño real.
- `loadingBuilder`/placeholder + `ListView/SliverGrid.builder` (solo se construye lo visible).

**Renderizado**
- `const` en todo widget estático; `RepaintBoundary` alrededor de gráficos que se animan (ya hay uno natural: la tarjeta de latencia con `duration: Duration.zero`).
- Listas siempre con `.builder`; `mainAxisExtent` fijo evita medir cada celda.
- Evita `Opacity`/`ClipRRect` anidados en listas largas; usa colores con alpha y `BoxDecoration`.

**Red**
- Debounce de búsqueda (400 ms, ya implementado), paginación `skip/limit` (24 por página) y `CancelToken` para búsquedas obsoletas.
- Reintentos solo en GET con backoff (ya implementado). Para caché HTTP real añade `dio_cache_interceptor`.
- El monitor de latencia es `autoDispose`: el polling se detiene al salir del Dashboard.

**Estado (Riverpod)**
- `ref.watch(provider.select((s) => s.campo))` para reconstruir solo lo necesario.
- Un provider por tarjeta del dashboard: cargas y fallos independientes, sin un `Future.wait` que bloquee todo.
- `autoDispose` para estado efímero (latencia); sin `autoDispose` para lo que debe sobrevivir al cambiar de pestaña (lista de Explorar).
- Override en tests: `ProviderScope(overrides: [apiClientProvider.overrideWithValue(fake)])`.
- Mide con Flutter DevTools (Performance overlay y *Rebuild stats*), en modo `--profile`.

## Siguientes pasos naturales
- Auth real: añade OAuth2/JWT en FastAPI y llama `tokenStorage.save(...)`; `AuthInterceptor` ya adjunta el Bearer y soporta refresh (pasa `refreshToken:` en `buildDio`).
- CRUD: crear/editar/borrar animes (`POST/PUT/DELETE /animes`); el cliente `ApiClient` ya expone `post/put/delete`.
- Rutas con URL en web: migrar el shell a `go_router` (`StatefulShellRoute`).
- Endpoint `/stats/timeline` (o campo `release_year`) en FastAPI para una tendencia de estrenos real.
