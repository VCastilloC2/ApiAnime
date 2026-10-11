def _genre(client, name="Acción"):
    r = client.post("/genres", json={"name": name})
    assert r.status_code == 201
    return r.json()["id"]


def _anime(client, **over):
    body = {"title": "Hellsing", "episodes": 13, "rating": 7.9, "genre_id": None, **over}
    r = client.post("/animes", json=body)
    assert r.status_code == 201, r.text
    return r.json()


def test_health_y_raiz(client):
    assert client.get("/").json()["status"] == "ok"
    assert client.get("/health").json()["database"] == "up"


def test_crud_anime(client):
    gid = _genre(client)
    created = _anime(client, genre_id=gid)
    assert created["genre_name"] == "Acción"
    aid = created["id"]

    assert client.get(f"/animes/{aid}").json()["title"] == "Hellsing"

    r = client.put(f"/animes/{aid}", json={"rating": 9.04})
    assert r.status_code == 200 and r.json()["rating"] == 9.0 and r.json()["title"] == "Hellsing"

    assert client.delete(f"/animes/{aid}").status_code == 204
    assert client.get(f"/animes/{aid}").status_code == 404


def test_listado_filtros_y_total(client):
    gid = _genre(client)
    _anime(client, title="Hellsing", genre_id=gid, rating=8.0)
    _anime(client, title="Hell Girl", rating=6.0)
    _anime(client, title="Naruto", rating=7.0)

    r = client.get("/animes", params={"search": "hell", "limit": 1})
    assert r.status_code == 200 and len(r.json()) == 1
    assert r.headers["X-Total-Count"] == "2"

    r = client.get("/animes", params={"search": "hell", "genre_id": gid})
    assert [a["title"] for a in r.json()] == ["Hellsing"]

    r = client.get("/animes", params={"sort_by": "rating", "order": "desc"})
    assert [a["title"] for a in r.json()] == ["Hellsing", "Naruto", "Hell Girl"]

    assert client.get("/animes", params={"search": ""}).status_code == 200
    assert client.get("/animes", params={"min_rating": 9, "max_rating": 1}).status_code == 422


def test_validaciones(client):
    assert client.post("/animes", json={"title": "X", "episodes": 1, "rating": 7, "genre_id": 999}).status_code == 400
    assert client.post("/animes", json={"title": "  ", "episodes": 1, "rating": 7}).status_code == 422
    assert client.post("/animes", json={"title": "X", "episodes": 0, "rating": 7}).status_code == 422
    aid = _anime(client)["id"]
    assert client.put(f"/animes/{aid}", json={"title": None}).status_code == 422
    assert client.put(f"/animes/{aid}", json={}).status_code == 422
    assert client.put("/animes/9999", json={"rating": 5}).status_code == 404


def test_generos_duplicados(client):
    _genre(client, "Drama")
    assert client.post("/genres", json={"name": "drama"}).status_code == 409


def test_estadisticas(client):
    gid = _genre(client)
    _anime(client, title="A", episodes=10, rating=9.0, genre_id=gid)
    _anime(client, title="B", episodes=20, rating=7.0, genre_id=gid)
    _anime(client, title="C", episodes=5, rating=3.0)

    s = client.get("/stats/summary").json()
    assert s["total_animes"] == 3 and s["animes_without_genre"] == 1 and s["total_episodes"] == 35

    g = client.get("/stats/by-genre").json()
    assert g == [{"genre": "Acción", "total_animes": 2, "avg_rating": 8.0, "total_episodes": 30}]

    assert client.get("/stats/top-rated", params={"limit": 1}).json()[0]["title"] == "A"

    dist = {b["label"]: b["total"] for b in client.get("/stats/rating-distribution").json()}
    assert dist == {"0-2": 0, "2-4": 1, "4-6": 0, "6-8": 1, "8-10": 1}
