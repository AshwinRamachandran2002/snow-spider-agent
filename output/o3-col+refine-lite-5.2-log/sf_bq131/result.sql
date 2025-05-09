WITH denmark_boundary AS (
    /* Denmark multipolygon from Wikidata = Q35 */
    SELECT TO_GEOGRAPHY("geometry") AS dk_geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS",
         LATERAL FLATTEN (INPUT => "all_tags") tag
    WHERE tag.value:"key"::STRING  = 'wikidata'
      AND tag.value:"value"::STRING = 'Q35'
    LIMIT 1
),                                             
bus_stops AS (
    /* All bus‑stop points that have a “network” tag and lie inside Denmark */
    SELECT 
        net_tag.value:"value"::STRING AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p,
         denmark_boundary,
         LATERAL FLATTEN (INPUT => p."all_tags") hw_tag,
         LATERAL FLATTEN (INPUT => p."all_tags") net_tag
    WHERE hw_tag.value:"key"::STRING   = 'highway'
      AND hw_tag.value:"value"::STRING = 'bus_stop'
      AND net_tag.value:"key"::STRING  = 'network'
      AND ST_CONTAINS(denmark_boundary.dk_geom,
                      TO_GEOGRAPHY(p."geometry"))
)
SELECT MAX(cnt) AS "number_of_bus_stops_for_top_network"
FROM (
    SELECT network, COUNT(*) AS cnt
    FROM bus_stops
    GROUP BY network
) t;