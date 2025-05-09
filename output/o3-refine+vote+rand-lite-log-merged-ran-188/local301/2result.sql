/* 4‑week sales change around 15‑June for 2018‑2020 */

WITH weekly_totals AS (          -- collapse the detailed table to 1 row per week
    SELECT
        "week_date",
        SUM("sales") AS total_sales
    FROM "cleaned_weekly_sales"
    GROUP BY "week_date"
),

weeks_with_year AS (            -- add year stamp
    SELECT
        CAST(substr(week_date,1,4) AS INTEGER)   AS year,
        DATE(week_date)                          AS week_start,
        total_sales                              AS sales
    FROM weekly_totals
    WHERE CAST(substr(week_date,1,4) AS INTEGER) IN (2018,2019,2020)
),

ordered_weeks AS (              -- give every week a position within its year
    SELECT
        year,
        week_start,
        sales,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY week_start) AS seq
    FROM weeks_with_year
),

/* identify the “mid‑June” reference week = week whose start‑date is
   closest to 15‑June of that year */
ref_seq AS (
    SELECT o1.year,
           o1.seq AS ref_seq
    FROM ordered_weeks o1
    JOIN (
        SELECT year,
               MIN(ABS(julianday(week_start)
                   - julianday(date(year||'-06-15')))) AS min_diff
        FROM ordered_weeks
        GROUP BY year
    ) o2
      ON o1.year = o2.year
     AND ABS(julianday(o1.week_start)
         - julianday(date(o1.year||'-06-15'))) = o2.min_diff
),

/* keep exactly four weeks before and four weeks after the reference week */
classified AS (
    SELECT
        ow.year,
        ow.sales,
        CASE
            WHEN ow.seq BETWEEN rs.ref_seq-4 AND rs.ref_seq-1 THEN 'before'
            WHEN ow.seq BETWEEN rs.ref_seq+1 AND rs.ref_seq+4 THEN 'after'
        END AS period
    FROM ordered_weeks ow
    JOIN ref_seq rs
      ON ow.year = rs.year
    WHERE ow.seq BETWEEN rs.ref_seq-4 AND rs.ref_seq+4
)

SELECT
    year,
    SUM(CASE WHEN period='before' THEN sales END) AS sales_before,
    SUM(CASE WHEN period='after'  THEN sales END) AS sales_after,
    ROUND(
        (SUM(CASE WHEN period='after' THEN sales END)
       - SUM(CASE WHEN period='before' THEN sales END))
       * 100.0
       / SUM(CASE WHEN period='before' THEN sales END), 4
    ) AS percentage_change
FROM classified
GROUP BY year
ORDER BY year;