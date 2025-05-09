WITH monthly_counts AS (
    SELECT
        "year",
        MONTH( TO_TIMESTAMP_NTZ( "date" / 1000000 ) ) AS month,
        COUNT(*)                                            AS motor_theft_cnt
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" BETWEEN 2010 AND 2016
    GROUP BY
        "year",
        MONTH( TO_TIMESTAMP_NTZ( "date" / 1000000 ) )
)
SELECT
    "year",
    MAX(motor_theft_cnt) AS highest_motor_thefts_in_one_month
FROM monthly_counts
GROUP BY "year"
ORDER BY "year";