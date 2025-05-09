/*  Number of bus stops for the bus‑network that has the most stops
    inside the Denmark (Wikidata = Q35) multipolygon boundary            */

WITH denmark AS (         -- Denmark geometry
    SELECT ST_UNION_AGG(TO_GEOGRAPHY(pf."geometry")) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::string   = 'wikidata'
      AND tag.value:"value"::string = 'Q35'
),

/* ------------------------------------------------------------------ */
/*  Explode tags for every point so we can pick   highway / platform  */
points_flat AS (
    SELECT
        p."osm_id"  AS OSM_ID,
        TO_GEOGRAPHY(p."geometry") AS geom,
        CASE WHEN t.value:"key"::string = 'network'          THEN t.value:"value"::string END AS network,
        CASE WHEN t.value:"key"::string = 'highway'          THEN t.value:"value"::string END AS highway,
        CASE WHEN t.value:"key"::string = 'public_transport' THEN t.value:"value"::string END AS pt
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN (INPUT => p."all_tags") t
    WHERE p."geometry" IS NOT NULL
),

/* ------------------------------------------------------------------ */
/*  Collapse the exploded rows back to one row per point via windows  */
bus_stops AS (
    SELECT
        OSM_ID,
        geom,
        MAX(network) OVER (PARTITION BY OSM_ID)  AS network,
        MAX(highway) OVER (PARTITION BY OSM_ID)  AS highway,
        MAX(pt)      OVER (PARTITION BY OSM_ID)  AS pt,
        ROW_NUMBER() OVER (PARTITION BY OSM_ID ORDER BY OSM_ID) AS rn
    FROM points_flat
),

/* ------------------------------------------------------------------ */
/*  Filter to true bus‑stop points that have a network tag            */
filtered_stops AS (
    SELECT geom, network
    FROM   bus_stops
    WHERE  rn = 1
      AND  ( highway = 'bus_stop' OR pt = 'platform' )
      AND  network IS NOT NULL
),

/* ------------------------------------------------------------------ */
/*  Keep only the stops located inside Denmark                        */
stops_in_denmark AS (
    SELECT fs.network
    FROM   filtered_stops fs
    JOIN   denmark d
      ON   ST_CONTAINS(d.geom, fs.geom)
)

/* ------------------------------------------------------------------ */
SELECT
    COUNT(*) AS "NUMBER_OF_STOPS"
FROM stops_in_denmark
GROUP BY network
ORDER BY COUNT(*) DESC NULLS LAST, network
LIMIT 1;