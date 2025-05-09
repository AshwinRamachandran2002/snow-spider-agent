WITH denmark AS (  -- Denmark multipolygon (wikidata = Q35)
    SELECT
        ST_UNION_AGG( TO_GEOGRAPHY("geometry") ) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
         LATERAL FLATTEN( INPUT => "all_tags") tag
    WHERE tag.value:"key"   = 'wikidata'
      AND tag.value:"value" = 'Q35'
),

bus_points AS (     -- every point that is a bus stop
    SELECT
        TO_GEOGRAPHY(p."geometry") AS geom,
        p."all_tags"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN( INPUT => p."all_tags") t
    WHERE t.value:"key" = 'highway'
      AND LOWER(t.value:"value"::string) = 'bus_stop'
),

bus_stops AS (      -- bus‑stop points that have a “network” tag
    SELECT
        t2.value:"value"::string AS network,
        bp.geom
    FROM bus_points bp,
         LATERAL FLATTEN( INPUT => bp."all_tags") t2
    WHERE t2.value:"key" = 'network'
      AND t2.value:"value" IS NOT NULL
)

SELECT
    MAX(cnt) AS "number_of_bus_stops"
FROM (
    SELECT
        network,
        COUNT(*) AS cnt
    FROM   bus_stops
    JOIN   denmark
           ON ST_CONTAINS( denmark.geom , bus_stops.geom )
    GROUP  BY network
);