WITH denmark AS (   -- Denmark multipolygon (wikidata = Q35)
    SELECT ST_GEOGFROMWKB("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         , LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE tag.value:"key"  = 'wikidata'
      AND tag.value:"value"= 'Q35'
      AND pf."feature_type" = 'multipolygons'
    ORDER BY pf."osm_timestamp" DESC NULLS LAST
    LIMIT 1
),

bus_points AS (      -- bus-stop points with their “network” tag
    SELECT
        ST_GEOGFROMWKB(p."geometry")                                   AS geom ,
        MAX(CASE WHEN tag.value:"key"='network' THEN tag.value:"value" END) AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
         , LATERAL FLATTEN(input => p."all_tags") tag
    WHERE p."geometry" IS NOT NULL
    GROUP BY p."geometry"
    HAVING MAX(CASE WHEN tag.value:"key"='highway' THEN tag.value:"value" END) = 'bus_stop'
),

network_counts AS (  -- count stops per network inside Denmark
    SELECT
        bp.network ,
        COUNT(*) AS stop_cnt
    FROM bus_points bp
         CROSS JOIN denmark d
    WHERE bp.network IS NOT NULL
      AND ST_CONTAINS(d.geom , bp.geom)
    GROUP BY bp.network
)

-- number of stops for the network having the most stops in Denmark
SELECT stop_cnt
FROM   network_counts
ORDER  BY stop_cnt DESC NULLS LAST
LIMIT  1;