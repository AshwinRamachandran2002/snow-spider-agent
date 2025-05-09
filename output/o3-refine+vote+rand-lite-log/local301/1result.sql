WITH formatted_sales AS (
    /* convert week_date (e.g. 31/8/20) → ISO date (2020‑08‑31) */
    SELECT
        week_date,
        sales,
        DATE(
              '20' || SUBSTR(week_date, LENGTH(week_date) - 1, 2)                              -- year
           || '-' ||
              printf('%02d',                                   -- month, 2‑digits
                     CAST(
                         SUBSTR(
                             SUBSTR(week_date, instr(week_date,'/') + 1),                       -- take “m/yy”
                             1,
                             instr( SUBSTR(week_date, instr(week_date,'/') + 1), '/') - 1
                         ) AS INTEGER)
              )
           || '-' ||
              printf('%02d',                                   -- day, 2‑digits
                     CAST(SUBSTR(week_date, 1, instr(week_date,'/') - 1) AS INTEGER))
        )                AS full_date
    FROM weekly_sales
),
target_years AS (
    SELECT
        full_date,
        sales,
        CAST(strftime('%Y', full_date) AS INTEGER) AS yr
    FROM formatted_sales
    WHERE yr IN (2018, 2019, 2020)
),
before_sales AS (
    /* 4 weeks leading up to (and incl.) 15‑Jun of each year */
    SELECT yr,
           SUM(sales) AS sales_before
    FROM (
        SELECT
            yr,
            full_date,
            sales,
            ROW_NUMBER() OVER (PARTITION BY yr ORDER BY full_date DESC) AS rn
        FROM target_years
        WHERE full_date <= DATE(yr || '-06-15')
    )
    WHERE rn <= 4
    GROUP BY yr
),
after_sales AS (
    /* 4 weeks following 15‑Jun of each year */
    SELECT yr,
           SUM(sales) AS sales_after
    FROM (
        SELECT
            yr,
            full_date,
            sales,
            ROW_NUMBER() OVER (PARTITION BY yr ORDER BY full_date ASC) AS rn
        FROM target_years
        WHERE full_date > DATE(yr || '-06-15')
    )
    WHERE rn <= 4
    GROUP BY yr
)
SELECT
    b.yr                         AS calendar_year,
    b.sales_before,
    a.sales_after,
    ( (a.sales_after - b.sales_before) * 100.0 / b.sales_before ) AS pct_change
FROM before_sales b
JOIN after_sales  a USING (yr)
ORDER BY calendar_year;