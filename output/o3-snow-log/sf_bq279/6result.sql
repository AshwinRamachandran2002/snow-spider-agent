WITH years AS (
    SELECT 2013 AS "year"
    UNION ALL
    SELECT 2014
),
counts AS (
    SELECT
        YEAR(TO_TIMESTAMP("modified_date" / 1000000))                                   AS "year",
        COUNT(DISTINCT CASE WHEN LOWER("status") = 'active' THEN "station_id" END)     AS "active_cnt",
        COUNT(DISTINCT CASE WHEN LOWER("status") = 'closed' THEN "station_id" END)     AS "closed_cnt"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") IN ('active', 'closed')
      AND YEAR(TO_TIMESTAMP("modified_date" / 1000000)) BETWEEN 2013 AND 2014
    GROUP BY YEAR(TO_TIMESTAMP("modified_date" / 1000000))
)

SELECT
    y."year",
    COALESCE(c."active_cnt", 0) AS "distinct_active_stations",
    COALESCE(c."closed_cnt", 0) AS "distinct_closed_stations"
FROM years y
LEFT JOIN counts c
       ON y."year" = c."year"
ORDER BY y."year";