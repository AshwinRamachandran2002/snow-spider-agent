WITH dk AS (
    /* Denmark multipolygon derived from Wikidata ID Q35 */
    SELECT TO_GEOGRAPHY(r."geometry") AS "dk_geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         LATERAL FLATTEN(input => r."all_tags") f
    WHERE f.value:"key"::STRING  = 'wikidata'
      AND f.value:"value"::STRING = 'Q35'
      AND r."visible" = TRUE
    LIMIT 1
),
roads AS (
    /* Clip every highway feature to Denmark and compute its length (metres) */
    SELECT
        f.value:"value"::STRING               AS "highway_type",
        ST_LENGTH(
            ST_INTERSECTION(dk."dk_geom", TO_GEOGRAPHY(pf."geometry"))
        )                                     AS "len_m"
    FROM dk,
         GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") f
    WHERE f.value:"key"::STRING = 'highway'
      AND ST_INTERSECTS(dk."dk_geom", TO_GEOGRAPHY(pf."geometry"))
)
SELECT
    "highway_type",
    SUM("len_m") AS "total_length_m"
FROM roads
GROUP BY "highway_type"
ORDER BY 2 DESC NULLS LAST
LIMIT 5;