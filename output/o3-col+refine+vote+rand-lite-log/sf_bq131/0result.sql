WITH denmark AS (           -- Denmark’s multipolygon boundary (wikidata = Q35)
    SELECT
        ST_UNION_AGG( ST_GEOGFROMWKB("geometry") ) AS geom
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  p,
          LATERAL FLATTEN( INPUT => p."all_tags") t
    WHERE p."feature_type" = 'multipolygons'
      AND t.value:"key"::STRING   = 'wikidata'
      AND t.value:"value"::STRING = 'Q35'
),
bus_pts AS (                -- point-features that are bus stops (+ their network tag)
    SELECT
        ST_GEOGFROMWKB(p."geometry")                                    AS geom,
        MAX( IFF(f.value:"key"::STRING = 'network' , 
                 f.value:"value"::STRING , NULL) )                      AS network,
        MAX( IFF(f.value:"key"::STRING = 'highway'
                 AND f.value:"value"::STRING = 'bus_stop', 1 , 0) )     AS is_bus_stop
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
          LATERAL FLATTEN( INPUT => p."all_tags") f
    WHERE p."geometry" IS NOT NULL
    GROUP BY p."geometry"
),
den_bus AS (                 -- bus stops that lie inside Denmark
    SELECT
        COALESCE(network , '(no network)') AS network
    FROM   bus_pts bp , denmark d
    WHERE  bp.is_bus_stop = 1
      AND  ST_INTERSECTS( d.geom , bp.geom )
)
SELECT 
    MAX(cnt) AS "bus_stop_count_for_top_network"   -- answer: number of stops of the largest network
FROM (
    SELECT network, COUNT(*) AS cnt
    FROM   den_bus
    GROUP  BY network
);