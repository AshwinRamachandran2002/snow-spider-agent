WITH latest_population AS (
    SELECT
        *
    FROM
        "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM"
    WHERE
        "country_name" = 'Singapore'
        AND "last_updated" = (
            SELECT MAX("last_updated")
            FROM "GEO_OPENSTREETMAP_WORLDPOP"."WORLDPOP"."POPULATION_GRID_1KM"
            WHERE "country_name" = 'Singapore' AND "last_updated" < '2023-01-01'
        )
        AND "population" > 0
        AND "geog" IS NOT NULL
),
hospitals_in_singapore AS (
    SELECT
        *
    FROM
        "GEO_OPENSTREETMAP_WORLDPOP"."GEO_OPENSTREETMAP"."PLANET_LAYERS"
    WHERE
        "layer_code" = 2110
        AND "geometry" IS NOT NULL
        AND ST_Y(ST_CENTROID(TO_GEOGRAPHY("geometry"))) BETWEEN 1.2 AND 1.5
        AND ST_X(ST_CENTROID(TO_GEOGRAPHY("geometry"))) BETWEEN 103.6 AND 104.0
),
distances AS (
    SELECT
        g."geo_id",
        g."population",
        MIN(ST_DISTANCE(TO_GEOGRAPHY(g."geog"), TO_GEOGRAPHY(h."geometry"))) AS "min_distance_to_hospital"
    FROM
        latest_population AS g,
        hospitals_in_singapore AS h
    GROUP BY
        g."geo_id",
        g."population"
),
max_distance AS (
    SELECT
        MAX("min_distance_to_hospital") AS "max_distance"
    FROM
        distances
)
SELECT
    ROUND(SUM(d."population"), 4) AS "total_population"
FROM
    distances d
CROSS JOIN
    max_distance
WHERE
    d."min_distance_to_hospital" = max_distance."max_distance";