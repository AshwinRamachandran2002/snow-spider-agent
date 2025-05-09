WITH denmark AS (  -- Denmark multipolygon (wikidata = Q35)
    SELECT TO_GEOGRAPHY(r."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         LATERAL FLATTEN(input => r."all_tags") t
    WHERE t.value:"key"::STRING   = 'wikidata'
      AND t.value:"value"::STRING = 'Q35'
      AND r."geometry" IS NOT NULL
      AND r."visible" = TRUE
    ORDER BY ST_AREA(TO_GEOGRAPHY(r."geometry")) DESC
    LIMIT 1
),
bus_stops AS (     -- all points tagged highway = bus_stop that carry a network tag
    SELECT 
        TO_GEOGRAPHY(p."geometry")        AS geom,
        net.value:"value"::STRING         AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
         ,LATERAL FLATTEN(input => p."all_tags") h
         ,LATERAL FLATTEN(input => p."all_tags") net
    WHERE h.value:"key"::STRING   = 'highway'
      AND h.value:"value"::STRING = 'bus_stop'
      AND net.value:"key"::STRING = 'network'
      AND p."geometry" IS NOT NULL
)
SELECT 
       network,
       COUNT(*) AS num_stops          -- number of bus stops for the biggest network
FROM   bus_stops, denmark
WHERE  ST_INTERSECTS(denmark.geom, bus_stops.geom)
GROUP  BY network
ORDER  BY num_stops DESC NULLS LAST
LIMIT  1;