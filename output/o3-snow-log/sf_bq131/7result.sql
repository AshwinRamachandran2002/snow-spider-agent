/*  Number of stops for the largest bus-stop network that lies inside Denmark   */

WITH denmark AS (            /* Denmark boundary (all geometries, wikidata = Q35) */
    SELECT
        ST_UNION_AGG( ST_GEOGFROMWKB("geometry") ) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE tag.value:"key"  ::string = 'wikidata'
      AND tag.value:"value"::string = 'Q35'
      AND pf."geometry" IS NOT NULL
),

bus_stops AS (               /* all points that are bus stops / platforms       */
    SELECT
        ST_GEOGFROMWKB(p."geometry")                                                  AS geom,
        MAX( CASE WHEN t.value:"key"::string = 'network'
                  THEN t.value:"value"::string END )                                  AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN( INPUT => p."all_tags") t
    WHERE p."geometry" IS NOT NULL
    GROUP BY p."geometry"                                         /* one record per point */
    HAVING MAX( CASE                                             /* keep only true stops  */
                   WHEN t.value:"key"::string = 'highway'
                        AND t.value:"value"::string = 'bus_stop'        THEN 1
                   WHEN t.value:"key"::string = 'public_transport'
                        AND t.value:"value"::string = 'platform'        THEN 1
                   ELSE 0
                END ) = 1
),

stops_per_network AS (       /* stops inside Denmark, counted per network       */
    SELECT
        bs.network,
        COUNT(*) AS stop_count
    FROM   bus_stops bs,
           denmark   d
    WHERE  bs.network IS NOT NULL
      AND  ST_CONTAINS(d.geom , bs.geom)
    GROUP BY bs.network
)

SELECT MAX(stop_count) AS stop_count   /* the largest network’s stop total      */
FROM   stops_per_network;