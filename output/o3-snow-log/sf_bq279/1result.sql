WITH years AS (               -- ensure the years 2013 & 2014 appear even if counts are 0
    SELECT 2013 AS "year"
    UNION ALL
    SELECT 2014
),
station_year_status AS (      -- derive year and keep only Active / Closed rows
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("modified_date", 6)) AS "year",   -- 6-digit scale → microseconds
        LOWER("status") AS "status",
        "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") IN ('active', 'closed')
),
year_status_counts AS (       -- count distinct stations by year & status
    SELECT
        "year",
        "status",
        COUNT(DISTINCT "station_id") AS "station_cnt"
    FROM station_year_status
    GROUP BY "year", "status"
)
SELECT                         -- pivot counts so each year has Active & Closed columns
    y."year",
    COALESCE(MAX(CASE WHEN c."status" = 'active' THEN c."station_cnt" END), 0) AS "active_station_count",
    COALESCE(MAX(CASE WHEN c."status" = 'closed' THEN c."station_cnt" END), 0) AS "closed_station_count"
FROM years y
LEFT JOIN year_status_counts c
       ON y."year" = c."year"
GROUP BY y."year"
ORDER BY y."year";