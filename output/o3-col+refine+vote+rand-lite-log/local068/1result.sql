WITH monthly AS (
    -- 1.  Count how many cities were inserted for Apr-Jun of each year
    SELECT
        substr(insert_date, 1, 4) AS yr,
        substr(insert_date, 6, 2) AS mon,
        COUNT(*)                  AS month_total
    FROM   "cities"
    WHERE  substr(insert_date, 1, 4) BETWEEN '2021' AND '2023'
      AND  substr(insert_date, 6, 2) IN ('04','05','06')
    GROUP  BY yr, mon
),
running AS (
    -- 2.  Compute the cumulative (running) total for each month across the years
    SELECT
        m1.yr,
        m1.mon,
        m1.month_total,
        (SELECT SUM(m2.month_total)
         FROM   monthly m2
         WHERE  m2.mon = m1.mon
           AND  CAST(m2.yr AS INTEGER) <= CAST(m1.yr AS INTEGER)) AS running_total
    FROM monthly m1
),
growth AS (
    -- 3.  Calculate YoY growth for both the monthly total and the running total
    SELECT
        r.yr,
        r.mon,
        r.month_total,
        r.running_total,
        ROUND(100.0 * (r.month_total  - r_prev.month_total)  / r_prev.month_total , 4) AS pct_growth_month,
        ROUND(100.0 * (r.running_total- r_prev.running_total)/ r_prev.running_total, 4) AS pct_growth_running
    FROM   running r
    JOIN   running r_prev
           ON  r_prev.mon = r.mon
           AND CAST(r_prev.yr AS INTEGER) = CAST(r.yr AS INTEGER) - 1
)
-- 4.  Show results only for 2022 and 2023
SELECT
    yr,
    mon,
    month_total,
    running_total,
    pct_growth_month,
    pct_growth_running
FROM   growth
WHERE  yr IN ('2022', '2023')
ORDER  BY mon, yr;