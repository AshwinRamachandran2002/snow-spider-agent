WITH peaks AS (
    /* Find each interest category’s single highest monthly composition */
    SELECT
        mp.interest_name          AS interest_name,
        im.month_year             AS peak_month,
        MAX(im.composition)       AS peak_composition
    FROM interest_metrics  AS im
    JOIN interest_map      AS mp
         ON im.interest_id = mp.id
    GROUP BY mp.interest_name
),
top10 AS (
    /* 10 largest peak-composition values */
    SELECT *
    FROM peaks
    ORDER BY peak_composition DESC
    LIMIT 10
),
bottom10 AS (
    /* 10 smallest peak-composition values */
    SELECT *
    FROM peaks
    ORDER BY peak_composition ASC
    LIMIT 10
)
/* Present Top-10 first (highest → lowest) then Bottom-10 (highest → lowest) */
SELECT
    'Top 10'          AS group_flag,
    peak_month        AS month_year,
    interest_name,
    ROUND(peak_composition,4) AS composition
FROM top10

UNION ALL

SELECT
    'Bottom 10',
    peak_month,
    interest_name,
    ROUND(peak_composition,4)
FROM bottom10

ORDER BY group_flag, composition DESC;