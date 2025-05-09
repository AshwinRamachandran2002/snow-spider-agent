WITH denmark AS (   /* Denmark boundary – Wikidata Q35 */
    SELECT TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS,
         LATERAL FLATTEN(input => "all_tags") tag
    WHERE tag.value:"key"::string  = 'wikidata'
      AND tag.value:"value"::string = 'Q35'
    LIMIT 1
),
bus_points AS (     /* every point with bus‑stop semantics + its network tag */
    SELECT
        MAX(CASE WHEN tag.value:"key"::string = 'network'
                 THEN tag.value:"value"::string END)                    AS network,
        TO_GEOGRAPHY(pfp."geometry")                                   AS geom,
        MAX(CASE WHEN ( tag.value:"key"::string = 'highway'
                        AND tag.value:"value"::string = 'bus_stop')
                  OR  ( tag.value:"key"::string = 'public_transport'
                        AND tag.value:"value"::string IN
                              ('platform','stop_position'))
                  THEN 1 ELSE 0 END)                                   AS is_bus
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pfp,
         LATERAL FLATTEN(input => pfp."all_tags") tag
    WHERE pfp."geometry" IS NOT NULL
    GROUP BY pfp."geometry"
),
bus_stops_in_denmark AS ( /* only bus stops with a network inside Denmark */
    SELECT bp.network
    FROM   bus_points bp , denmark d
    WHERE  bp.is_bus = 1
      AND  bp.network IS NOT NULL
      AND  ST_CONTAINS(d.geom , bp.geom)
),
network_counts AS (        /* number of stops per network */
    SELECT network, COUNT(*) AS num_stops
    FROM   bus_stops_in_denmark
    GROUP BY network
)
SELECT num_stops           /* highest stop‑count */
FROM   network_counts
ORDER BY num_stops DESC NULLS LAST, network
LIMIT 1;