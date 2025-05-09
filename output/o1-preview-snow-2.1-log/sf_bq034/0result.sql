SELECT
    "id",
    "name"
FROM
    GHCN_D.GHCN_D.GHCND_STATIONS
WHERE
    ST_DISTANCE(
        ST_MAKEPOINT("longitude", "latitude"),
        ST_MAKEPOINT(-87.6847, 41.8319)
    ) <= 50000;