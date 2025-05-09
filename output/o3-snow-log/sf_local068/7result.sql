/* ----------------------------------------------------------
   Cities added in April-June (2021-2023) with YoY metrics
   ---------------------------------------------------------- */
WITH months_years AS (           -- every (year, month) pair we need
    SELECT column1::NUMBER AS "yr",
           column2::NUMBER AS "mon"
    FROM VALUES
         (2021,4),(2021,5),(2021,6),
         (2022,4),(2022,5),(2022,6),
         (2023,4),(2023,5),(2023,6)
),
raw_counts AS (                  -- actual insert counts
    SELECT  EXTRACT(YEAR  FROM TO_DATE("insert_date",'YYYY-MM-DD'))  AS "yr",
            EXTRACT(MONTH FROM TO_DATE("insert_date",'YYYY-MM-DD'))  AS "mon",
            COUNT(*)                                                AS "cnt"
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE   EXTRACT(MONTH FROM TO_DATE("insert_date",'YYYY-MM-DD')) IN (4,5,6)
      AND   EXTRACT(YEAR  FROM TO_DATE("insert_date",'YYYY-MM-DD')) BETWEEN 2021 AND 2023
    GROUP BY "yr","mon"
),
month_totals AS (                -- ensure months with zero inserts appear
    SELECT  m."yr",
            m."mon",
            COALESCE(r."cnt",0) AS "month_total"
    FROM    months_years m
    LEFT JOIN raw_counts r
           ON m."yr" = r."yr"
          AND m."mon"= r."mon"
),
running AS (                     -- cumulative running total per month
    SELECT  "yr",
            "mon",
            "month_total",
            SUM("month_total") OVER (PARTITION BY "mon"
                                     ORDER BY "yr"
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "running_total"
    FROM    month_totals
),
final_calc AS (                  -- add previous-year values for YoY %
    SELECT  "yr"                                         AS "year",
            DECODE("mon",4,'April',5,'May',6,'June')     AS "month",
            "month_total",
            "running_total",
            LAG("month_total")   OVER (PARTITION BY "mon" ORDER BY "yr") AS "prev_month_total",
            LAG("running_total") OVER (PARTITION BY "mon" ORDER BY "yr") AS "prev_running_total"
    FROM    running
)
SELECT  "year",
        "month",
        "month_total"    AS total_cities_added,
        "running_total"  AS cumulative_running_total,
        CASE WHEN "prev_month_total" = 0 THEN NULL
             ELSE ROUND( ( "month_total" - "prev_month_total") * 100.0
                         / NULLIF("prev_month_total",0), 2)
        END              AS yoy_month_total_growth_pct,
        CASE WHEN "prev_running_total" = 0 THEN NULL
             ELSE ROUND( ( "running_total" - "prev_running_total") * 100.0
                         / NULLIF("prev_running_total",0), 2)
        END              AS yoy_running_total_growth_pct
FROM    final_calc
WHERE   "year" IN (2022, 2023)            -- exclude baseline 2021
ORDER BY "year", "month";