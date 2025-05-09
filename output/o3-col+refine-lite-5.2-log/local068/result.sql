/* ------------------------------------------------------------
   Cities added in Apr, May, Jun (2021‑2023)  ►
   – monthly totals
   – running‑totals per month across years
   – YoY % growth (using 2021 as baseline, but show only 2022‑23)
   ------------------------------------------------------------ */
WITH filtered AS (                       -- narrow scan to 2021‑04‑01 … 2023‑06‑30
    SELECT  "insert_date"
    FROM    "cities"
    WHERE   "insert_date" >= '2021-04-01'
      AND   "insert_date" <  '2023-07-01'
      AND   substr("insert_date",6,2) IN ('04','05','06')
),
monthly AS (                             -- counts per year‑month
    SELECT
        substr("insert_date",1,4)  AS "year",
        substr("insert_date",6,2)  AS "month",
        COUNT(*)                   AS "monthly_total"
    FROM   filtered
    GROUP  BY "year","month"
),
running AS (                             -- cumulative running total for that month
    SELECT
        "year",
        "month",
        "monthly_total",
        SUM("monthly_total") OVER (PARTITION BY "month"
                                   ORDER BY "year") AS "running_total"
    FROM   monthly
),
growth AS (                              -- YoY growth calculations
    SELECT
        "year",
        "month",
        "monthly_total",
        "running_total",
        ROUND(
            100.0 * ("monthly_total" - LAG("monthly_total")
                     OVER (PARTITION BY "month" ORDER BY "year"))
            / NULLIF(LAG("monthly_total")
                     OVER (PARTITION BY "month" ORDER BY "year"),0), 2
        )  AS "yoy_monthly_growth_pct",
        ROUND(
            100.0 * ("running_total" - LAG("running_total")
                     OVER (PARTITION BY "month" ORDER BY "year"))
            / NULLIF(LAG("running_total")
                     OVER (PARTITION BY "month" ORDER BY "year"),0), 2
        )  AS "yoy_running_growth_pct"
    FROM   running
)
SELECT
    "year",
    CASE "month"
         WHEN '04' THEN 'April'
         WHEN '05' THEN 'May'
         WHEN '06' THEN 'June'
    END                       AS "month_name",
    "monthly_total",
    "running_total",
    "yoy_monthly_growth_pct",
    "yoy_running_growth_pct"
FROM   growth
WHERE  "year" IN ('2022','2023')          -- only report 2022‑23
ORDER  BY "month","year";