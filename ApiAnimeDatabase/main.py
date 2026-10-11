import time
import mysql.connector
import requests

# Configuración de tu conexión a MySQL (con la base de datos incluida)
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '0220',  # Cambia por tu contraseña de MySQL
    'database': 'db_anime',  # <--- IMPORTANTE: Esto evita el error de "No database selected"
}

def setup_database():
  """Crea la base de datos y las tablas si no existen."""
  # Conectamos primero sin especificar base de datos solo para asegurar su creación
  conn = mysql.connector.connect(
      host=db_config['host'],
      user=db_config['user'],
      password=db_config['password'],
      database=db_config['database']
  )
  cursor = conn.cursor()
  cursor.close()
  conn.close()


def fetch_and_populate_animes():
  setup_database()

  # Conexión principal especificando la base de datos 'db_anime'
  conn = mysql.connector.connect(
      host=db_config['host'],
      user=db_config['user'],
      password=db_config['password'],
      database=db_config['database'],
  )

  cursor = conn.cursor()

  # Asegurarnos de usar la base de datos explícitamente
  cursor.execute('USE db_anime;')

  # Crear las tablas si no existen
  cursor.execute("""
        CREATE TABLE IF NOT EXISTS tb_genres (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) NOT NULL UNIQUE
        );
    """)

  cursor.execute("""
        CREATE TABLE IF NOT EXISTS tb_animes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(100) NOT NULL,
            episodes INT NOT NULL,
            rating DECIMAL(3,1) NOT NULL,
            genre_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT fk_anime_genre FOREIGN KEY (genre_id) REFERENCES tb_genres(id) ON DELETE SET NULL
        );
    """)
  conn.commit()

  # Caché local de géneros para evitar consultas repetidas
  genre_cache = {}
  cursor.execute('SELECT id, name FROM tb_genres;')
  for g_id, g_name in cursor.fetchall():
    genre_cache[g_name] = g_id

  target_count = 15000
  inserted_count = 0
  offset = 0
  limit = 20  # Límite por página permitido por Kitsu

  print('Iniciando extracción de animes reales desde la API de Kitsu...')

  while inserted_count < target_count:
    url = f'https://kitsu.io/api/edge/anime?page[limit]={limit}&page[offset]={offset}&include=categories'

    max_retries = 3
    success = False
    response = None

    for attempt in range(max_retries):
      try:
        response = requests.get(
            url,
            headers={
                'Accept': 'application/vnd.api+json',
                'Content-Type': 'application/vnd.api+json',
            },
            timeout=15,
        )
        success = True
        break
      except (requests.exceptions.Timeout, requests.exceptions.ConnectionError):
        print(
            f'Conexión lenta o timeout. Reintento {attempt + 1} de'
            f' {max_retries}...'
        )
        time.sleep(3)

    if not success:
      print('No se pudo conectar a la API de Kitsu. Saltando bloque...')
      offset += limit
      continue

    if response.status_code == 429:
      print('Límite de peticiones alcanzado. Esperando 5 segundos...')
      time.sleep(5)
      continue

    if response.status_code != 200:
      print(f'Error en la API (Código {response.status_code}). Reintentando...')
      time.sleep(2)
      continue

    data = response.json()
    anime_list = data.get('data', [])

    if not anime_list:
      print('No se encontraron más animes disponibles en la API de Kitsu.')
      break

    included_map = {}
    if 'included' in data:
      for inc in data['included']:
        if inc.get('type') == 'categories':
          inc_id = inc.get('id')
          inc_title = inc.get('attributes', {}).get('title')
          if inc_title:
            included_map[inc_id] = inc_title

    # 1. Crea una lista para almacenar el lote de la página actual
    batch_animes = []

    for anime in anime_list:
      if inserted_count + len(batch_animes) >= target_count:
        break

      attributes = anime.get('attributes', {})
      titles = attributes.get('titles', {})
      title = (
          attributes.get('canonicalTitle')
          or titles.get('en')
          or titles.get('en_jp')
          or 'Anime Desconocido'
      )
      title = title[:100]

      episodes = attributes.get('episodeCount')
      if not episodes or not isinstance(episodes, int):
        episodes = 12

      raw_rating = attributes.get('averageRating')
      try:
        rating = (
            round(float(raw_rating) / 10.0, 1)
            if raw_rating
            else 5.0
        )
      except (ValueError, TypeError):
        rating = 5.0
      if rating > 10.0:
        rating = 10.0

      genre_id = None
      relationships = anime.get('relationships', {})
      categories_rel = relationships.get('categories', {}).get('data', [])

      if categories_rel and included_map:
        cat_id = categories_rel[0].get('id')
        g_name = included_map.get(cat_id)
        if g_name:
          g_name = g_name[:50]
          if g_name in genre_cache:
            genre_id = genre_cache[g_name]
          else:
            cursor.execute(
                'INSERT IGNORE INTO tb_genres (name) VALUES (%s);', (g_name,)
            )
            conn.commit()
            cursor.execute('SELECT id FROM tb_genres WHERE name = %s;', (g_name,))
            res = cursor.fetchone()
            if res:
              genre_id = res[0]
              genre_cache[g_name] = genre_id

      # 2. En lugar de ejecutar el insert aquí, lo agregamos a la lista del lote
      batch_animes.append((title, episodes, rating, genre_id))

    # 3. Insertamos todo el lote de golpe con executemany (Esto evita el error 10054)
    if batch_animes:
      try:
        cursor.executemany(
            """
                INSERT INTO tb_animes (title, episodes, rating, genre_id)
                VALUES (%s, %s, %s, %s)
            """,
            batch_animes,
        )
        conn.commit()
        inserted_count += len(batch_animes)
        print(f'-> Progreso: {inserted_count} / {target_count} animes guardados.')
      except mysql.connector.Error as db_err:
        print(f'⚠️ Error al insertar el lote en la base de datos: {db_err}')
        conn.rollback()

    offset += limit
    time.sleep(0.4)

  cursor.close()
  conn.close()
  print('¡Base de datos poblada exitosamente con datos reales de Kitsu!')


if __name__ == '__main__':
  fetch_and_populate_animes()