/* -----------------------------------------------------------
   Largest number of bus-stops belonging to one network
   inside Denmark (wikidata = Q35)
   -----------------------------------------------------------*/
WITH denmark AS (                             -- Denmark multipolygon
    SELECT ST_UNION_AGG(TO_GEOGRAPHY("geometry")) AS geog
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r ,
           LATERAL FLATTEN( INPUT => r."all_tags") tag
    WHERE  tag.value:"key"::string   = 'wikidata'
      AND  tag.value:"value"::string = 'Q35'
),
point_tags AS (                               -- explode tags of every point
    SELECT  f."osm_id"                               AS id ,
            f."geometry"                             AS geom_bin ,
            t.value:"key"::string                    AS tag_key ,
            t.value:"value"::string                  AS tag_val
    FROM    GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS f ,
            LATERAL FLATTEN( INPUT => f."all_tags")  t
    WHERE   f."geometry" IS NOT NULL
),
bus_stop_points AS (                           -- rebuild points w/ needed info
    SELECT  id ,
            TO_GEOGRAPHY( MIN( geom_bin ) )                AS geog ,
            MAX( CASE WHEN tag_key = 'network'
                       THEN tag_val END )                  AS network ,
            MAX( CASE WHEN ( tag_key = 'highway'
                              AND tag_val = 'bus_stop')
                        OR ( tag_key = 'public_transport'
                              AND tag_val = 'platform')
                       THEN 1 ELSE 0 END )                 AS is_bus_stop
    FROM    point_tags
    GROUP BY id
    HAVING  is_bus_stop = 1          -- keep only bus-stops / platforms
       AND  network     IS NOT NULL  -- with a network tag
),
bus_stops_in_dk AS (                           -- limit to those in Denmark
    SELECT  b.network
    FROM    bus_stop_points b
    CROSS JOIN denmark d
    WHERE   ST_CONTAINS( d.geog , b.geog )
),
network_counts AS (                            -- count per network
    SELECT  network ,
            COUNT(*) AS bus_stop_count
    FROM    bus_stops_in_dk
    GROUP BY network
)
SELECT  bus_stop_count
FROM    network_counts
ORDER BY bus_stop_count DESC NULLS LAST
LIMIT 1;