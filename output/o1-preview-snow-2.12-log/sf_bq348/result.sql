SELECT COALESCE(hn."username", 'Unknown') AS "username", COUNT(DISTINCT hn."id") AS "number_of_removed_nodes"
FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."HISTORY_NODES" AS hn,
     LATERAL FLATTEN(input => hn."all_tags") AS tag
WHERE hn."latitude" IS NOT NULL
  AND hn."longitude" IS NOT NULL
  AND tag.value:"key"::STRING = 'amenity'
  AND tag.value:"value"::STRING IN ('hospital', 'clinic', 'doctors')
  AND ST_CONTAINS(
    TO_GEOGRAPHY('POLYGON((31.1798246 18.4519921,54.3798246 18.4519921,54.3798246 33.6519921,31.1798246 33.6519921,31.1798246 18.4519921))'),
    TO_GEOGRAPHY(ST_POINT(hn."longitude", hn."latitude"))
  )
  AND hn."id" NOT IN (
    SELECT pn."id"
    FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_NODES" AS pn
  )
GROUP BY COALESCE(hn."username", 'Unknown')
ORDER BY "number_of_removed_nodes" DESC NULLS LAST, "username" ASC
LIMIT 3;