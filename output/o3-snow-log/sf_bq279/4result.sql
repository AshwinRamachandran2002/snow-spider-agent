WITH station_year_status AS (
    SELECT
        YEAR(TO_TIMESTAMP_NTZ("modified_date", 6))                                           AS "year",
        CASE 
            WHEN LOWER("status") IN ('active', 'open') THEN 'active'
            WHEN LOWER("status") IN ('closed', 'inactive', 'removed') THEN 'closed'
            ELSE LOWER("status")
        END                                                                                 AS "status",
        "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE "modified_date" IS NOT NULL
), agg AS (
    SELECT
        "year",
        "status",
        COUNT(DISTINCT "station_id") AS "cnt"
    FROM station_year_status
    WHERE "year" IN (2013, 2014)
      AND "status" IN ('active', 'closed')
    GROUP BY "year", "status"
), all_combos AS (
    SELECT y."year", s."status"
    FROM (SELECT 2013 AS "year" UNION ALL SELECT 2014) y
    CROSS JOIN (SELECT 'active' AS "status" UNION ALL SELECT 'closed') s
)
SELECT
    ac."year",
    ac."status",
    COALESCE(a."cnt", 0) AS "distinct_station_count"
FROM all_combos ac
LEFT JOIN agg a
       ON ac."year" = a."year"
      AND ac."status" = a."status"
ORDER BY ac."year", ac."status";