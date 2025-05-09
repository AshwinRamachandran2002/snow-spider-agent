WITH daily_counts AS (
    SELECT 
        "date"                                  AS incident_date,
        COUNT(*)                                AS daily_count
    FROM 
        AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE 
        TRIM(UPPER("descript")) = 'PUBLIC INTOXICATION'
        AND YEAR("date") = 2016
    GROUP BY 
        "date"
)
SELECT 
    TO_CHAR(incident_date, 'YYYY-MM-DD')       AS date_with_second_highest_z
FROM (
    SELECT
        incident_date,
        (daily_count - AVG(daily_count) OVER()) / STDDEV_POP(daily_count) OVER()  AS z_score
    FROM 
        daily_counts
)
ORDER BY 
    z_score DESC NULLS LAST
OFFSET 1 ROWS               -- skip the highest Z-score
FETCH NEXT 1 ROWS ONLY;     -- return the second-highest