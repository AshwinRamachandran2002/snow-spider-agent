WITH average_costs AS (
    SELECT 
        EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')) AS "Year",
        m."region" AS "Region",
        AVG(t."quantity" * p."price") AS "Average_Cost"
    FROM 
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS" t
    JOIN 
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_MEMBERS" m
            ON t."member_id" = m."member_id"
    JOIN 
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES" p
            ON t."ticker" = p."ticker" AND t."txn_date" = p."market_date"
    WHERE 
        t."txn_type" = 'BUY'
        AND EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')) > (
            SELECT MIN(EXTRACT(YEAR FROM TO_DATE("txn_date", 'DD-MM-YYYY'))) 
            FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS"
        )
    GROUP BY 
        EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')), 
        m."region"
),
ranked_costs AS (
    SELECT
        ac."Year",
        ac."Region",
        ac."Average_Cost",
        RANK() OVER (PARTITION BY ac."Year" ORDER BY ac."Average_Cost" DESC NULLS LAST) AS "Rank"
    FROM
        average_costs ac
),
percentage_change AS (
    SELECT
        rc."Year",
        rc."Region",
        ROUND(rc."Average_Cost", 4) AS "Average_Cost",
        rc."Rank",
        ROUND(((rc."Average_Cost" - prev_ac."Average_Cost") / NULLIF(prev_ac."Average_Cost", 0)) * 100, 4) AS "Annual_Percentage_Change"
    FROM
        ranked_costs rc
    LEFT JOIN
        average_costs prev_ac
            ON rc."Region" = prev_ac."Region" AND prev_ac."Year" = rc."Year" - 1
)
SELECT
    "Year",
    "Region",
    "Average_Cost" AS "Average_Purchase_Cost",
    "Rank",
    "Annual_Percentage_Change"
FROM
    percentage_change
ORDER BY
    "Year", "Rank";