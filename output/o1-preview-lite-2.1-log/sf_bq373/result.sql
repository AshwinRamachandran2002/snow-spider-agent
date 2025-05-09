SELECT
    ROUND(MEDIAN("AverageMonthlySpending"), 4) AS "Median_Average_Monthly_Spending"
FROM (
    SELECT
        soh."customerid",
        SUM(soh."totaldue") / 12 AS "AverageMonthlySpending"
    FROM "ADVENTUREWORKS"."ADVENTUREWORKS"."SALESORDERHEADER" AS soh
    WHERE soh."orderdate" >= '2014-01-01 00:00:00' AND soh."orderdate" < '2015-01-01 00:00:00'
    GROUP BY soh."customerid"
);