/*  Denmark’s largest bus-network – number of stops                                  */
/*  1. find Denmark multipolygon (wikidata = Q35)                                    */
/*  2. take every point tagged highway=bus_stop and having a network tag             */
/*  3. keep only those stops located inside Denmark                                  */
/*  4. count stops per network and return the highest count                          */

WITH denmark AS (      /* Denmark geometry ---------------------------------------*/
    SELECT
        ST_GEOMFROMWKB(pf."geometry") AS geom
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
          LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::string   = 'wikidata'
      AND tag.value:"value"::string = 'Q35'
    QUALIFY ROW_NUMBER() OVER (ORDER BY pf."osm_timestamp" DESC NULLS LAST) = 1
),

bus_stops AS (         /* bus stops carrying a “network” tag ---------------------*/
    SELECT
        ST_GEOMFROMWKB(p."geometry")            AS geom ,
        net_tag.value:"value"::string           AS network
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p
          , LATERAL FLATTEN(input => p."all_tags") net_tag      -- network tag
          , LATERAL FLATTEN(input => p."all_tags") hw_tag       -- highway tag
    WHERE p."geometry" IS NOT NULL
      AND net_tag.value:"key"::string = 'network'
      AND hw_tag.value:"key"::string  = 'highway'
      AND hw_tag.value:"value"::string = 'bus_stop'
),

stops_in_denmark AS ( /* restrict to Denmark ------------------------------------*/
    SELECT bs.network
    FROM   bus_stops bs
    JOIN   denmark  d
           ON ST_CONTAINS(d.geom , bs.geom)
    WHERE  bs.network IS NOT NULL
)

SELECT
    COUNT(*) AS number_of_stops        -- answer: most stops on any network
FROM   stops_in_denmark
GROUP  BY network
ORDER  BY number_of_stops DESC NULLS LAST
LIMIT  1;