/* 1) Geometry of Denmark from wikidata = Q35               */
/* 2) All bus_stop points that have a “network” tag          */
/* 3) Count stops per network that fall inside Denmark       */
/* 4) Return the largest stop count                          */
WITH denmark AS (                 -- multipolygon of Denmark
    SELECT
        ST_UNION_AGG(TO_GEOGRAPHY("geometry")) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         ,LATERAL FLATTEN(input => pf."all_tags") f
    WHERE f.value:"key"::string  = 'wikidata'
      AND f.value:"value"::string = 'Q35'
),

bus_points AS (                   -- every bus stop point with a network tag
    SELECT
        TO_GEOGRAPHY(p."geometry")                   AS geom ,
        net_tag.value:"value"::string                AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
         ,LATERAL FLATTEN(input => p."all_tags") hw_tag
         ,LATERAL FLATTEN(input => p."all_tags") net_tag
    WHERE p."geometry" IS NOT NULL
      AND hw_tag.value:"key"::string   = 'highway'
      AND hw_tag.value:"value"::string = 'bus_stop'
      AND net_tag.value:"key"::string  = 'network'
),

bus_stops AS (                     -- count stops per network inside Denmark
    SELECT
        bp.network,
        COUNT(*) AS stop_count
    FROM bus_points bp
    JOIN denmark d
      ON ST_WITHIN(bp.geom , d.geom)
    GROUP BY bp.network
)

SELECT
    MAX(stop_count) AS max_bus_stops   -- largest bus-network stop count
FROM bus_stops;