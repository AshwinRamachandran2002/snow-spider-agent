WITH data AS (
    SELECT
        CAST(strftime('%Y', substr("insert_date", 1, 10)) AS INTEGER) AS year,
        CAST(strftime('%m', substr("insert_date", 1, 10)) AS INTEGER) AS month,
        COUNT(*) AS monthly_total
    FROM "cities"
    WHERE strftime('%m', substr("insert_date", 1, 10)) IN ('04', '05', '06')
      AND strftime('%Y', substr("insert_date", 1, 10)) BETWEEN '2021' AND '2023'
    GROUP BY year, month
),
running AS (
    SELECT
        d.year,
        d.month,
        d.monthly_total,
        (
            SELECT SUM(d2.monthly_total)
            FROM data d2
            WHERE d2.month = d.month
              AND d2.year <= d.year
        ) AS running_total
    FROM data d
),
growth AS (
    SELECT
        r.year,
        r.month,
        r.monthly_total,
        r.running_total,
        ROUND(
            100.0 * (r.monthly_total - p.monthly_total) / p.monthly_total,
            2
        ) AS monthly_yoy_growth,
        ROUND(
            100.0 * (r.running_total - p.running_total) / p.running_total,
            2
        ) AS running_yoy_growth
    FROM running r
    JOIN running p
      ON p.month = r.month
     AND p.year  = r.year - 1
    WHERE r.year IN (2022, 2023)   -- exclude the 2021 baseline from output
)
SELECT
    g.year,
    CASE g.month
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
    END          AS month_name,
    g.monthly_total,
    g.running_total,
    g.monthly_yoy_growth,
    g.running_yoy_growth
FROM growth g
ORDER BY g.year, g.month;