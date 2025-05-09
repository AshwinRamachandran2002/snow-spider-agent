WITH base AS (
    SELECT
        TO_DATE("insert_date")                                                         AS insert_dt,
        EXTRACT(year  FROM TO_DATE("insert_date"))                                     AS yr,
        EXTRACT(month FROM TO_DATE("insert_date"))                                     AS mth,
        CASE EXTRACT(month FROM TO_DATE("insert_date"))
            WHEN 4 THEN 'April'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
        END                                                                            AS month_name
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE EXTRACT(year  FROM TO_DATE("insert_date")) BETWEEN 2021 AND 2023
      AND EXTRACT(month FROM TO_DATE("insert_date")) IN (4,5,6)
), 
month_counts AS (
    SELECT
        yr,
        mth,
        month_name,
        COUNT(*)                                                                       AS monthly_total
    FROM base
    GROUP BY yr, mth, month_name
), 
cumulative_totals AS (
    SELECT
        mc.*,
        SUM(monthly_total) OVER (PARTITION BY mth ORDER BY yr ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                                                        AS running_total
    FROM month_counts mc
), 
yoy AS (
    SELECT
        yr                                                                             AS year,
        month_name,
        monthly_total,
        running_total,
        ROUND( (monthly_total - LAG(monthly_total) OVER (PARTITION BY mth ORDER BY yr))
               / NULLIF(LAG(monthly_total) OVER (PARTITION BY mth ORDER BY yr),0) * 100, 2)
                                                                                        AS monthly_yoy_growth_pct,
        ROUND( (running_total - LAG(running_total) OVER (PARTITION BY mth ORDER BY yr))
               / NULLIF(LAG(running_total) OVER (PARTITION BY mth ORDER BY yr),0) * 100, 2)
                                                                                        AS running_yoy_growth_pct
    FROM cumulative_totals
)
SELECT
    year,
    month_name,
    monthly_total,
    running_total,
    monthly_yoy_growth_pct,
    running_yoy_growth_pct
FROM yoy
WHERE year IN (2022, 2023)
ORDER BY year,
         CASE month_name WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6 END;