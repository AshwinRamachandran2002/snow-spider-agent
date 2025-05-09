WITH city_month_counts AS (   -- how many cities were inserted each month
    SELECT
        EXTRACT(year  FROM TO_DATE("insert_date"))                 AS "YEAR",
        EXTRACT(month FROM TO_DATE("insert_date"))                 AS "MONTH_NUM",
        COUNT(*)                                                   AS "MONTHLY_TOTAL"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE EXTRACT(month FROM TO_DATE("insert_date")) IN (4,5,6)      -- April-June only
      AND EXTRACT(year  FROM TO_DATE("insert_date")) BETWEEN 2021 AND 2023
    GROUP BY
        EXTRACT(year  FROM TO_DATE("insert_date")),
        EXTRACT(month FROM TO_DATE("insert_date"))
), ------------------------------------------------------------------
year_month_grid AS (          -- ensure months with zero inserts are present
    SELECT y."YEAR", m."MONTH_NUM"
    FROM (SELECT 2021 AS "YEAR" UNION ALL SELECT 2022 UNION ALL SELECT 2023) y
    CROSS JOIN (SELECT 4 AS "MONTH_NUM" UNION ALL SELECT 5 UNION ALL SELECT 6) m
), ------------------------------------------------------------------
monthly AS (                  -- join counts to grid, fill blanks with 0
    SELECT
        g."YEAR",
        g."MONTH_NUM",
        COALESCE(c."MONTHLY_TOTAL",0) AS "MONTHLY_TOTAL"
    FROM year_month_grid g
    LEFT JOIN city_month_counts c
           ON g."YEAR" = c."YEAR"
          AND g."MONTH_NUM" = c."MONTH_NUM"
), ------------------------------------------------------------------
running AS (                  -- cumulative running total per month across years
    SELECT
        "YEAR",
        "MONTH_NUM",
        "MONTHLY_TOTAL",
        SUM("MONTHLY_TOTAL")
          OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR") AS "CUMULATIVE_TOTAL"
    FROM monthly
), ------------------------------------------------------------------
growth AS (                   -- year-over-year % growth calculations
    SELECT
        "YEAR",
        "MONTH_NUM",
        "MONTHLY_TOTAL",
        "CUMULATIVE_TOTAL",
        /* % growth of the month vs previous year */
        CASE
            WHEN LAG("MONTHLY_TOTAL") OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR") = 0 THEN NULL
            ELSE ROUND(
                 ("MONTHLY_TOTAL"
                 - LAG("MONTHLY_TOTAL") OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR"))
                 / NULLIF(LAG("MONTHLY_TOTAL") OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR"),0)
                 * 100 , 2)
        END AS "MONTHLY_YOY_PCT",
        /* % growth of the running total vs previous year */
        CASE
            WHEN LAG("CUMULATIVE_TOTAL") OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR") = 0 THEN NULL
            ELSE ROUND(
                 ("CUMULATIVE_TOTAL"
                 - LAG("CUMULATIVE_TOTAL") OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR"))
                 / NULLIF(LAG("CUMULATIVE_TOTAL") OVER (PARTITION BY "MONTH_NUM" ORDER BY "YEAR"),0)
                 * 100 , 2)
        END AS "CUMULATIVE_YOY_PCT"
    FROM running
) -------------------------------------------------------------------
SELECT
    "YEAR",
    CASE "MONTH_NUM" WHEN 4 THEN 'April' WHEN 5 THEN 'May' WHEN 6 THEN 'June' END AS "MONTH",
    "MONTHLY_TOTAL",
    "CUMULATIVE_TOTAL",
    "MONTHLY_YOY_PCT",
    "CUMULATIVE_YOY_PCT"
FROM growth
WHERE "YEAR" IN (2022, 2023)          -- exclude baseline 2021
ORDER BY "YEAR", "MONTH_NUM";