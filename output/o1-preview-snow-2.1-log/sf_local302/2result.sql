SELECT
    attribute,
    ROUND(AVG(percentage_change), 4) AS Average_Percentage_Change
FROM
(
    -- For 'region'
    SELECT
        'region' AS attribute,
        ((a."average_sales_after" - b."average_sales_before") / NULLIF(b."average_sales_before", 0)) * 100 AS percentage_change
    FROM
        (SELECT "region", AVG("sales") AS "average_sales_before"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATEADD(week, -12, DATE '2020-06-15')
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATE '2020-06-15'
         GROUP BY "region") b
    INNER JOIN
        (SELECT "region", AVG("sales") AS "average_sales_after"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATE '2020-06-15'
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATEADD(week, 12, DATE '2020-06-15')
         GROUP BY "region") a
    ON a."region" = b."region"
    
    UNION ALL
    
    -- For 'platform'
    SELECT
        'platform' AS attribute,
        ((a."average_sales_after" - b."average_sales_before") / NULLIF(b."average_sales_before", 0)) * 100 AS percentage_change
    FROM
        (SELECT "platform", AVG("sales") AS "average_sales_before"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATEADD(week, -12, DATE '2020-06-15')
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATE '2020-06-15'
         GROUP BY "platform") b
    INNER JOIN
        (SELECT "platform", AVG("sales") AS "average_sales_after"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATE '2020-06-15'
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATEADD(week, 12, DATE '2020-06-15')
         GROUP BY "platform") a
    ON a."platform" = b."platform"
    
    UNION ALL
    
    -- For 'age_band'
    SELECT
        'age_band' AS attribute,
        ((a."average_sales_after" - b."average_sales_before") / NULLIF(b."average_sales_before", 0)) * 100 AS percentage_change
    FROM
        (SELECT "age_band", AVG("sales") AS "average_sales_before"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATEADD(week, -12, DATE '2020-06-15')
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATE '2020-06-15'
         GROUP BY "age_band") b
    INNER JOIN
        (SELECT "age_band", AVG("sales") AS "average_sales_after"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATE '2020-06-15'
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATEADD(week, 12, DATE '2020-06-15')
         GROUP BY "age_band") a
    ON a."age_band" = b."age_band"
    
    UNION ALL

    -- For 'demographic'
    SELECT
        'demographic' AS attribute,
        ((a."average_sales_after" - b."average_sales_before") / NULLIF(b."average_sales_before", 0)) * 100 AS percentage_change
    FROM
        (SELECT "demographic", AVG("sales") AS "average_sales_before"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATEADD(week, -12, DATE '2020-06-15')
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATE '2020-06-15'
         GROUP BY "demographic") b
    INNER JOIN
        (SELECT "demographic", AVG("sales") AS "average_sales_after"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATE '2020-06-15'
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATEADD(week, 12, DATE '2020-06-15')
         GROUP BY "demographic") a
    ON a."demographic" = b."demographic"
    
    UNION ALL

    -- For 'customer_type'
    SELECT
        'customer_type' AS attribute,
        ((a."average_sales_after" - b."average_sales_before") / NULLIF(b."average_sales_before", 0)) * 100 AS percentage_change
    FROM
        (SELECT "customer_type", AVG("sales") AS "average_sales_before"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATEADD(week, -12, DATE '2020-06-15')
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATE '2020-06-15'
         GROUP BY "customer_type") b
    INNER JOIN
        (SELECT "customer_type", AVG("sales") AS "average_sales_after"
         FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
         WHERE TO_DATE("week_date", 'YYYY-MM-DD') >= DATE '2020-06-15'
           AND TO_DATE("week_date", 'YYYY-MM-DD') < DATEADD(week, 12, DATE '2020-06-15')
         GROUP BY "customer_type") a
    ON a."customer_type" = b."customer_type"
) t
GROUP BY attribute
ORDER BY average_percentage_change ASC
LIMIT 1;