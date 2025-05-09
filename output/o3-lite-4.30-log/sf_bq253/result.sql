WITH q1095 AS (                                                         -- geometry of the Q1095 multipolygon
    SELECT TO_GEOGRAPHY("geometry") AS geo
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE tag.value:"key"  = 'wikidata'
      AND tag.value:"value" = 'Q1095'
    LIMIT 1
),
candidate_rel AS (                                                      -- relations in the same area, with name but no wikidata tag
    SELECT r."id"                                   AS rel_id,
           MAX(CASE WHEN t.value:"key" = 'name'
                    THEN t.value:"value"::STRING END) AS rel_name
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r,
         q1095,
         LATERAL FLATTEN(input => r."all_tags") t
    WHERE ST_INTERSECTS(TO_GEOGRAPHY(r."geometry"), q1095.geo)
    GROUP BY r."id"
    HAVING COUNT_IF(t.value:"key" = 'name')    > 0     -- must have a name
       AND COUNT_IF(t.value:"key" = 'wikidata') = 0     -- but no wikidata tag
),
relation_members AS (                                                    -- explode members of each candidate relation
    SELECT cr.rel_id,
           (m.value:"id")::NUMBER AS member_id
    FROM candidate_rel cr
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_RELATIONS r
         ON r."id" = cr.rel_id,
         LATERAL FLATTEN(input => r."members") m
),
members_with_wikidata AS (                                               -- members that themselves carry a wikidata tag
    SELECT DISTINCT rm.rel_id
    FROM relation_members rm
    JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         ON pf."osm_way_id" = rm.member_id
         OR pf."osm_id"     = rm.member_id,
         LATERAL FLATTEN(input => pf."all_tags") t
    WHERE t.value:"key" = 'wikidata'
),
member_totals AS (                                                       -- total member count for every candidate relation
    SELECT rel_id, COUNT(*) AS total_members
    FROM relation_members
    GROUP BY rel_id
),
final_candidates AS (                                                    -- keep only relations with ≥1 wikidata‑tagged member
    SELECT cr.rel_name,
           mt.total_members,
           cr.rel_id
    FROM candidate_rel          cr
    JOIN members_with_wikidata  mw ON mw.rel_id = cr.rel_id
    JOIN member_totals          mt ON mt.rel_id = cr.rel_id
)
SELECT rel_name AS name
FROM final_candidates
ORDER BY total_members DESC NULLS LAST, rel_id
LIMIT 1;