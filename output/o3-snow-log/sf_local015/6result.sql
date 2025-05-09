WITH

/* 1.  Collisions that include at least one MOTORCYCLE party wearing a helmet */
helmet_cases AS (
    SELECT DISTINCT p."case_id"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.PARTIES p
    WHERE p."statewide_vehicle_type" ILIKE '%motorcycle%'
      AND (p."party_safety_equipment_1" ILIKE '%helmet%'
           OR p."party_safety_equipment_2" ILIKE '%helmet%')
),

/* 2.  Collisions that include a MOTORCYCLE party with NO helmet
       (and none of the motorcycle parties in the same collision wore one) */
no_helmet_cases AS (
    SELECT DISTINCT p."case_id"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.PARTIES p
    WHERE p."statewide_vehicle_type" ILIKE '%motorcycle%'
      AND NOT (p."party_safety_equipment_1" ILIKE '%helmet%'
               OR p."party_safety_equipment_2" ILIKE '%helmet%')
      AND p."case_id" NOT IN (SELECT "case_id" FROM helmet_cases)   -- exclude mixed-helmet collisions
),

/* 3.  Aggregate collisions & fatalities for helmet users */
helmet_stats AS (
    SELECT
        COUNT(*)                                               AS collisions_with_helmet,
        COALESCE(SUM(c."motorcyclist_killed_count"), 0)        AS fatalities_with_helmet
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c
    JOIN helmet_cases h
      ON c."case_id" = h."case_id"
),

/* 4.  Aggregate collisions & fatalities for non-helmet users */
no_helmet_stats AS (
    SELECT
        COUNT(*)                                               AS collisions_no_helmet,
        COALESCE(SUM(c."motorcyclist_killed_count"), 0)        AS fatalities_no_helmet
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c
    JOIN no_helmet_cases nh
      ON c."case_id" = nh."case_id"
)

/* 5.  Compute fatality rates (percentage = fatalities / collisions * 100) */
SELECT
    ROUND( (hs.fatalities_with_helmet  / NULLIF(hs.collisions_with_helmet ,0)) * 100, 4 )
        AS "fatality_rate_with_helmet_percent",
    ROUND( (nhs.fatalities_no_helmet   / NULLIF(nhs.collisions_no_helmet ,0)) * 100, 4 )
        AS "fatality_rate_no_helmet_percent"
FROM helmet_stats      hs
CROSS JOIN no_helmet_stats nhs;