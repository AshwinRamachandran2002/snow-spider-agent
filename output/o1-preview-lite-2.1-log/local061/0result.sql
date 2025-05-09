SELECT
    AVG(m.projected_sales_usd) AS "Average_Monthly_Projected_Sales_in_USD"
FROM (
    SELECT
        m.month,
        m.avg_sales,
        ex."to_us" AS exchange_rate,
        m.avg_sales * ex."to_us" AS projected_sales_usd
    FROM (
        SELECT
            month,
            AVG(total_sales) AS avg_sales
        FROM (
            SELECT
                strftime('%Y', s."time_id") AS year,
                strftime('%m', s."time_id") AS month,
                SUM(s."amount_sold") AS total_sales
            FROM "sales" AS s
            JOIN "customers" AS c ON s."cust_id" = c."cust_id"
            JOIN "countries" AS co ON c."country_id" = co."country_id"
            WHERE co."country_name" = 'France' AND strftime('%Y', s."time_id") IN ('2019', '2020')
            GROUP BY year, month
        ) AS monthly_totals
        GROUP BY month
    ) AS m
    JOIN "currency" AS ex ON ex."country" = 'France' AND ex."year" = 2021 AND ex."month" = CAST(m.month AS INTEGER)
) AS m;