WITH months AS (
    SELECT '2014-01' AS "YearMonth" UNION ALL
    SELECT '2014-02' UNION ALL
    SELECT '2014-03' UNION ALL
    SELECT '2014-04' UNION ALL
    SELECT '2014-05' UNION ALL
    SELECT '2014-06' UNION ALL
    SELECT '2014-07' UNION ALL
    SELECT '2014-08' UNION ALL
    SELECT '2014-09' UNION ALL
    SELECT '2014-10' UNION ALL
    SELECT '2014-11' UNION ALL
    SELECT '2014-12'
),
customers AS (
    SELECT DISTINCT "customerid"
    FROM ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("orderdate", 'YYYY-MM-DD HH24:MI:SS')) = 2014
),
customer_months AS (
    SELECT c."customerid", m."YearMonth"
    FROM customers c CROSS JOIN months m
),
customer_spending AS (
    SELECT
        "customerid",
        TO_CHAR(TO_TIMESTAMP("orderdate", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM') AS "YearMonth",
        SUM("totaldue") AS "MonthlyTotal"
    FROM
        ADVENTUREWORKS.ADVENTUREWORKS.SALESORDERHEADER
    WHERE
        EXTRACT(YEAR FROM TO_TIMESTAMP("orderdate", 'YYYY-MM-DD HH24:MI:SS')) = 2014
    GROUP BY
        "customerid", TO_CHAR(TO_TIMESTAMP("orderdate", 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM')
),
customer_monthly_totals AS (
    SELECT
        cm."customerid",
        cm."YearMonth",
        COALESCE(cs."MonthlyTotal", 0) AS "MonthlyTotal"
    FROM
        customer_months cm
    LEFT JOIN
        customer_spending cs
    ON
        cm."customerid" = cs."customerid" AND cm."YearMonth" = cs."YearMonth"
),
customer_average_monthly_spending AS (
    SELECT
        "customerid",
        SUM("MonthlyTotal") / 12 AS "AverageMonthlySpending"
    FROM
        customer_monthly_totals
    GROUP BY
        "customerid"
)
SELECT
    MEDIAN("AverageMonthlySpending") AS "median_average_monthly_spending"
FROM
    customer_average_monthly_spending;