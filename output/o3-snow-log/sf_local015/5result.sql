WITH motorcycle_collisions AS (          -- all collisions that involve a motorcycle
    SELECT "case_id",
           "motorcyclist_killed_count"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS"
    WHERE  "motorcycle_collision" = 1
),
/* collisions where at least one motorcyclist party had a HELMET USED */
helmet_used_collisions AS (
    SELECT DISTINCT p."case_id"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."PARTIES"  p
    JOIN   motorcycle_collisions mc
           ON mc."case_id" = p."case_id"
    WHERE  p."statewide_vehicle_type" ILIKE '%motorcycle%'
      AND ( p."party_safety_equipment_1" ILIKE '%helmet%' 
         OR p."party_safety_equipment_2" ILIKE '%helmet%' )
      AND NOT ( p."party_safety_equipment_1" ILIKE '%helmet%not%'   -- exclude “helmet NOT used”
             OR p."party_safety_equipment_2" ILIKE '%helmet%not%' )
),
/* collisions where at least one motorcyclist party had a HELMET **NOT** USED */
helmet_not_used_collisions AS (
    SELECT DISTINCT p."case_id"
    FROM   "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."PARTIES"  p
    JOIN   motorcycle_collisions mc
           ON mc."case_id" = p."case_id"
    WHERE  p."statewide_vehicle_type" ILIKE '%motorcycle%'
      AND ( p."party_safety_equipment_1" ILIKE '%helmet%not%' 
         OR p."party_safety_equipment_2" ILIKE '%helmet%not%' )
),
/* aggregate fatalities & collisions for the HELMET-USED group */
agg_yes AS (
    SELECT 
        SUM(mc."motorcyclist_killed_count") AS "helmet_yes_fatalities",
        COUNT(DISTINCT mc."case_id")        AS "helmet_yes_collisions"
    FROM   motorcycle_collisions mc
    JOIN   helmet_used_collisions hu
           ON hu."case_id" = mc."case_id"
),
/* aggregate fatalities & collisions for the HELMET-NOT-USED group */
agg_no AS (
    SELECT 
        SUM(mc."motorcyclist_killed_count") AS "helmet_no_fatalities",
        COUNT(DISTINCT mc."case_id")        AS "helmet_no_collisions"
    FROM   motorcycle_collisions mc
    JOIN   helmet_not_used_collisions hn
           ON hn."case_id" = mc."case_id"
)
/* final side-by-side fatality rates */
SELECT
    ay."helmet_yes_fatalities",
    ay."helmet_yes_collisions",
    ROUND(ay."helmet_yes_fatalities" * 100.0 / NULLIF(ay."helmet_yes_collisions",0), 2) AS "helmet_yes_fatality_pct",
    an."helmet_no_fatalities",
    an."helmet_no_collisions",
    ROUND(an."helmet_no_fatalities" * 100.0 / NULLIF(an."helmet_no_collisions",0), 2)   AS "helmet_no_fatality_pct"
FROM   agg_yes ay
CROSS JOIN agg_no an;