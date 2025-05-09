WITH month_counts AS (
    SELECT
        "year",
        EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("date" / 1000000)) AS "month",
        COUNT(*) AS "monthly_thefts"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE
        "primary_type" = 'MOTOR VEHICLE THEFT'
        AND "year" BETWEEN 2010 AND 2016
    GROUP BY
        "year",
        EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("date" / 1000000))
),
yearly_max AS (
    SELECT
        "year",
        MAX("monthly_thefts") AS "max_thefts_in_month"
    FROM month_counts
    GROUP BY "year"
)
SELECT
    "year",
    "max_thefts_in_month"
FROM yearly_max
ORDER BY "year" ASC;