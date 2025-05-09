/* Five longest highway types (total kilometres) that lie inside the
   Denmark multipolygon (wikidata = Q35) using PLANET_FEATURES           */

WITH denmark AS (      -- exact Denmark multipolygon geometry
    SELECT TO_GEOGRAPHY(r."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         LATERAL FLATTEN (INPUT => PARSE_JSON(r."all_tags")) f
    WHERE f.value:"key"   ::STRING = 'wikidata'
      AND f.value:"value" ::STRING = 'Q35'
      AND r."geometry" IS NOT NULL
    LIMIT 1
)

SELECT
    t.value:"value"::STRING                                            AS "highway_type",
    ROUND( SUM( ST_LENGTH( TO_GEOGRAPHY(pf."geometry") ) ) / 1000 , 2) AS "total_len_km"
FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
     ,LATERAL FLATTEN (INPUT => PARSE_JSON(pf."all_tags")) t
     ,denmark d
WHERE t.value:"key"::STRING = 'highway'          -- only highway features
  AND pf."geometry" IS NOT NULL                  -- must have geometry
  AND ST_INTERSECTS( TO_GEOGRAPHY(pf."geometry"), d.geom )  -- inside DK
GROUP BY 1
ORDER BY "total_len_km" DESC NULLS LAST, "highway_type"
LIMIT 5;