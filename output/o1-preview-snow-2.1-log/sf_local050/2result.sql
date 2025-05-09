WITH monthly_sales AS (
    SELECT
        t."calendar_month_number" AS "month",
        t."calendar_year" AS "year",
        SUM(s."amount_sold" * COALESCE(cur."to_us", 1)) AS "total_sales"
    FROM
        "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES" s
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS" c ON s."cust_id" = c."cust_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES" ctr ON c."country_id" = ctr."country_id"
        JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES" t ON s."time_id" = t."time_id"
        LEFT JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CURRENCY" cur ON ctr."country_name" = cur."country"
            AND t."calendar_year" = cur."year" AND t."calendar_month_number" = cur."month"
    WHERE
        ctr."country_name" = 'France' AND t."calendar_year" IN (2019, 2020)
    GROUP BY
        t."calendar_year", t."calendar_month_number"
),
monthly_projection AS (
    SELECT
        ms2020."month",
        ms2020."total_sales" AS "sales_2020",
        ms2019."total_sales" AS "sales_2019",
        ROUND(
            CASE
                WHEN ms2019."total_sales" IS NOT NULL AND ms2019."total_sales" != 0 THEN
                    ms2020."total_sales" * (1 + (ms2020."total_sales" - ms2019."total_sales") / ms2019."total_sales")
                ELSE
                    ms2020."total_sales"
            END, 4
        ) AS "projected_sales_2021"
    FROM
        (SELECT * FROM monthly_sales WHERE "year" = 2020) ms2020
        LEFT JOIN (SELECT * FROM monthly_sales WHERE "year" = 2019) ms2019 ON ms2020."month" = ms2019."month"
)
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "projected_sales_2021") AS "median_average_monthly_projected_sales_in_USD"
FROM
    monthly_projection;