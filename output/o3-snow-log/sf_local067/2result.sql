WITH "DEC_PROFIT" AS (
    SELECT
        s."cust_id",
        SUM(
            s."amount_sold" - (c."unit_cost" * s."quantity_sold")
        ) AS "profit"
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE."SALES"     s
        INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COSTS"      c
            ON  s."prod_id"   = c."prod_id"
            AND s."time_id"   = c."time_id"
            AND s."channel_id"= c."channel_id"
            AND s."promo_id"  = c."promo_id"
        INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."CUSTOMERS"  cu
            ON s."cust_id" = cu."cust_id"
        INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."COUNTRIES"  co
            ON cu."country_id" = co."country_id"
        INNER JOIN COMPLEX_ORACLE.COMPLEX_ORACLE."TIMES"      t
            ON s."time_id" = t."time_id"
    WHERE
          co."country_name"        = 'Italy'
      AND t."calendar_year"        = 2021
      AND t."calendar_month_number"= 12
    GROUP BY
        s."cust_id"
),
"TIERED" AS (
    SELECT
        "cust_id",
        "profit",
        NTILE(10) OVER (ORDER BY "profit" DESC) AS "tier"
    FROM
        "DEC_PROFIT"
)
SELECT
    "tier",
    MIN("profit") AS "lowest_profit",
    MAX("profit") AS "highest_profit"
FROM
    "TIERED"
GROUP BY
    "tier"
ORDER BY
    "tier";