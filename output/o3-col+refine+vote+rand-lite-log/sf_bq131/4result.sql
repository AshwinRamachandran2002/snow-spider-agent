WITH denmark AS (   -- Denmark multipolygon boundary (wikidata = Q35)
    SELECT TO_GEOGRAPHY(pf."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
         LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE tag.value:"key"::STRING  ILIKE '%wikidata%'
      AND tag.value:"value"::STRING = 'Q35'
      AND pf."feature_type" = 'multipolygons'
    LIMIT 1
),
bus_points AS (     -- Every OSM point tagged as a bus stop
    SELECT
        TO_GEOGRAPHY(p."geometry")                                         AS geom_pt,
        COALESCE(
            MAX(CASE WHEN tag.value:"key"::STRING ILIKE '%network%'  THEN tag.value:"value"::STRING END),
            MAX(CASE WHEN tag.value:"key"::STRING ILIKE '%operator%' THEN tag.value:"value"::STRING END),
            'UNKNOWN'
        ) AS bus_network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p,
         LATERAL FLATTEN (INPUT => p."all_tags") tag
    WHERE tag.value:"value"::STRING ILIKE '%bus_stop%'
    GROUP BY p."geometry"
),
denmark_bus AS (    -- Bus stops that fall inside Denmark
    SELECT bp.bus_network
    FROM   bus_points bp, denmark d
    WHERE  ST_CONTAINS(d.geom, bp.geom_pt)
),
network_counts AS ( -- Count stops per network
    SELECT bus_network, COUNT(*) AS num_stops
    FROM   denmark_bus
    GROUP  BY bus_network
)
-- Return the number of stops for the network with the most stops
SELECT num_stops
FROM   network_counts
ORDER  BY num_stops DESC NULLS LAST
LIMIT 1;