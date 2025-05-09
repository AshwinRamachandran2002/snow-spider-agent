WITH denmark AS (   -- Denmark boundary (wikidata = Q35)
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
         LATERAL FLATTEN(input => "all_tags") t
    WHERE t.value:"key"::string  = 'wikidata'
      AND t.value:"value"::string = 'Q35'
    LIMIT 1
),
bus_stops AS (      -- Every bus-stop point together with its network tag (if any)
    SELECT
        COALESCE(                          -- network name (or “Unknown”)
            MAX(CASE
                    WHEN t.value:"key"::string = 'network'
                    THEN t.value:"value"::string
                END
            ),
            'Unknown'
        )                                  AS network,
        TO_GEOGRAPHY(p."geometry")         AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN(input => p."all_tags") t
    WHERE p."geometry" IS NOT NULL
    GROUP BY p."geometry"                 -- one row per point
    HAVING                                -- keep only highway = bus_stop points
        MAX(CASE
                WHEN t.value:"key"::string = 'highway'
                 AND t.value:"value"::string = 'bus_stop'
                THEN 1 ELSE 0
            END
        ) = 1
)
SELECT
    network,
    COUNT(*) AS stop_count
FROM bus_stops, denmark
WHERE ST_CONTAINS(denmark.geom, bus_stops.geom)
GROUP BY network
ORDER BY stop_count DESC NULLS LAST
LIMIT 1;