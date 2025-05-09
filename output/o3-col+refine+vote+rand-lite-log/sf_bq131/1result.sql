WITH den AS (
    -- Denmark multipolygon from wikidata = Q35
    SELECT TO_GEOGRAPHY(r."geometry") AS "dk_geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
         LATERAL FLATTEN (INPUT => r."all_tags") kv
    WHERE kv.value:"key"::STRING  = 'wikidata'
      AND kv.value:"value"::STRING = 'Q35'
    LIMIT 1
),
network_counts AS (
    -- count bus-stop points per network that fall inside Denmark
    SELECT
        COALESCE(net.value:"value"::STRING, '<no_network_tag>') AS "network",
        COUNT(*)                                                AS "num_stops"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p,
         LATERAL FLATTEN (INPUT => p."all_tags") hwy,
         LATERAL FLATTEN (INPUT => p."all_tags") net,
         den
    WHERE p."geometry" IS NOT NULL
      AND hwy.value:"key"::STRING  = 'highway'
      AND hwy.value:"value"::STRING ILIKE '%bus%stop%'
      AND net.value:"key"::STRING  = 'network'
      AND ST_CONTAINS(den."dk_geom", TO_GEOGRAPHY(p."geometry"))
    GROUP BY 1
)
-- return the stop count of the network with the most Danish bus stops
SELECT "num_stops"
FROM network_counts
ORDER BY "num_stops" DESC NULLS LAST
LIMIT 1;