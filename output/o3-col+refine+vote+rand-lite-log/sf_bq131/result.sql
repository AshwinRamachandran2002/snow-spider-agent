WITH denmark AS (
  SELECT TO_GEOGRAPHY(r."geometry") AS "dk_geog"
  FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
       LATERAL FLATTEN(input => r."all_tags") tag
  WHERE tag.value:"key"::STRING ILIKE 'wikidata'
    AND tag.value:"value"::STRING = 'Q35'
  LIMIT 1
),
network_counts AS (
  SELECT 
    net_tag.value:"value"::STRING AS "bus_network",
    COUNT(*)                    AS "num_stops_in_dk"
  FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
       LATERAL FLATTEN(input => p."all_tags") hw_tag,
       LATERAL FLATTEN(input => p."all_tags") net_tag,
       denmark
  WHERE hw_tag.value:"key"::STRING  = 'highway'
    AND hw_tag.value:"value"::STRING = 'bus_stop'
    AND net_tag.value:"key"::STRING  = 'network'
    AND ST_CONTAINS(denmark."dk_geog", TO_GEOGRAPHY(p."geometry"))
  GROUP BY net_tag.value:"value"::STRING
)
SELECT MAX("num_stops_in_dk") AS "max_stops_any_dk_network"
FROM network_counts;