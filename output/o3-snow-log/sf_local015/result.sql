WITH mcy_parties AS (               -- 1) all motorcycle parties with helmet flag
    SELECT
        "case_id",
        CASE
            WHEN ("party_safety_equipment_1" ILIKE '%helmet%'
               OR "party_safety_equipment_2" ILIKE '%helmet%')
            THEN 1 ELSE 0
        END                     AS "helmet_used",
        COALESCE("party_number_killed",0) AS "party_number_killed"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.PARTIES
    WHERE "statewide_vehicle_type" ILIKE '%motorcycle%'
),

mcy_cases AS (                     -- 2) collapse to one row per collision
    SELECT
        "case_id",
        MAX("helmet_used")                     AS "helmet_involved",   -- 1 if ANY motorcyclist wore helmet
        SUM("party_number_killed")             AS "motorcyclist_fatalities"
    FROM mcy_parties
    GROUP BY "case_id"
),

summary AS (                       -- 3) totals by helmet group
    SELECT
        CASE WHEN "helmet_involved" = 1 THEN 'Helmet' ELSE 'No Helmet' END AS "helmet_usage",
        COUNT(*)                                   AS "collision_count",
        SUM("motorcyclist_fatalities")             AS "fatalities"
    FROM mcy_cases
    GROUP BY "helmet_usage"
)

-- 4) final fatality-rate output
SELECT
    "helmet_usage",
    "fatalities"                       AS "motorcyclist_fatalities",
    "collision_count"                  AS "motorcycle_collisions",
    ROUND("fatalities" / "collision_count" * 100, 4) AS "fatality_rate_percent"
FROM summary
ORDER BY "helmet_usage";