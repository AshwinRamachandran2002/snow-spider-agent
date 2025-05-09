SELECT
    "Tier",
    ROUND(MAX("Profit"), 4) AS "Highest_Profit",
    ROUND(MIN("Profit"), 4) AS "Lowest_Profit"
FROM (
    SELECT
        "cust_id",
        SUM("Profit") AS "Profit",
        NTILE(10) OVER (ORDER BY SUM("Profit") DESC NULLS LAST) AS "Tier"
    FROM (
        SELECT
            s."cust_id",
            (s."amount_sold" - (c."unit_cost" * s."quantity_sold")) AS "Profit"
        FROM COMPLEX_ORACLE.COMPLEX_ORACLE."SALES" s
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES" t ON s."time_id" = t."time_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS" cu ON s."cust_id" = cu."cust_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES" co ON cu."country_id" = co."country_id"
        JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS" c ON s."prod_id" = c."prod_id" AND s."time_id" = c."time_id"
        WHERE co."country_name" = 'Italy' AND t."calendar_month_number" = 12 AND t."calendar_year" = 2021
    ) profit_data
    GROUP BY "cust_id"
) tiered_data
GROUP BY "Tier"
ORDER BY "Tier";