WITH raw AS (
    SELECT "region"        AS attr_val, 'region'        AS attr_type, "week_date", "sales" FROM "cleaned_weekly_sales"
    UNION ALL
    SELECT "platform",         'platform',              "week_date", "sales" FROM "cleaned_weekly_sales"
    UNION ALL
    SELECT "age_band",         'age_band',              "week_date", "sales" FROM "cleaned_weekly_sales"
    UNION ALL
    SELECT "demographic",      'demographic',           "week_date", "sales" FROM "cleaned_weekly_sales"
    UNION ALL
    SELECT "customer_type",    'customer_type',         "week_date", "sales" FROM "cleaned_weekly_sales"
), before_after AS (
    SELECT
        attr_type,
        attr_val,
        SUM(CASE WHEN "week_date" <  '2020-06-15' THEN "sales" END) AS before_sales,
        SUM(CASE WHEN "week_date" >= '2020-06-15' THEN "sales" END) AS after_sales
    FROM raw
    WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
    GROUP BY attr_type, attr_val
), pct_change AS (
    SELECT
        attr_type,
        ROUND( (after_sales - before_sales) * 100.0 / NULLIF(before_sales,0), 4) AS pct_change
    FROM before_after
), avg_change AS (
    SELECT
        attr_type AS attribute_type,
        ROUND(AVG(pct_change), 4) AS average_percentage_change
    FROM pct_change
    GROUP BY attr_type
)
SELECT attribute_type, average_percentage_change
FROM   avg_change
ORDER  BY average_percentage_change
LIMIT 1;