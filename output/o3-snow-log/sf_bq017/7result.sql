/*  Five longest highway types inside Denmark (wikidata = Q35) by total length  */
WITH denmark AS (        -- Denmark multipolygon
    SELECT
        ST_GEOGFROMWKB(pf."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") t
    WHERE t.value:"key"::STRING   = 'wikidata'
      AND t.value:"value"::STRING = 'Q35'
      AND pf."geometry" IS NOT NULL
    LIMIT 1                    -- one multipolygon is sufficient
),
highways AS (            -- lengths of every highway feature intersecting Denmark
    SELECT
        tags.value:"value"::STRING                                       AS "highway_type",
        ST_LENGTH(
            ST_INTERSECTION(
                ST_GEOGFROMWKB(pf."geometry"),     -- feature geometry
                d.geom                             -- Denmark polygon
            )
        ) AS len_m
    FROM denmark d
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
      ON pf."geometry" IS NOT NULL
      ,LATERAL FLATTEN(input => pf."all_tags") tags
    WHERE tags.value:"key"::STRING = 'highway'
      AND ST_INTERSECTS(ST_GEOGFROMWKB(pf."geometry"), d.geom)
)
SELECT
    "highway_type",
    ROUND( SUM(len_m) / 1000 , 4 ) AS "total_length_km"   -- convert to kilometres
FROM highways
GROUP BY "highway_type"
ORDER BY "total_length_km" DESC NULLS LAST
LIMIT 5;