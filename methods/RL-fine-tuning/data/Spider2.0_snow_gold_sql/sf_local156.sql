SELECT
  sub."Year",
  sub."region" AS "Region",
  ROUND(sub."Average_Purchase_Cost", 4) AS "Average_Purchase_Cost",
  RANK() OVER (
    PARTITION BY sub."Year" 
    ORDER BY sub."Average_Purchase_Cost" DESC NULLS LAST
  ) AS "Rank",
  ROUND(
    (
      sub."Average_Purchase_Cost" - LAG(sub."Average_Purchase_Cost") OVER (PARTITION BY sub."region" ORDER BY sub."Year")
    ) / NULLIF(LAG(sub."Average_Purchase_Cost") OVER (PARTITION BY sub."region" ORDER BY sub."Year"), 0) * 100, 2
  ) AS "Annual_Percentage_Change"
FROM (
  SELECT 
    m."region", 
    EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')) AS "Year", 
    AVG(t."quantity" * p."price") AS "Average_Purchase_Cost"
  FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS" t
  JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_MEMBERS" m
    ON t."member_id" = m."member_id"
  JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_PRICES" p
    ON t."ticker" = p."ticker" 
    AND TO_DATE(t."txn_date", 'DD-MM-YYYY') = TO_DATE(p."market_date", 'DD-MM-YYYY')
  WHERE t."txn_type" = 'BUY' 
    AND t."ticker" = 'BTC' 
    AND EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')) > (
      SELECT MIN(EXTRACT(YEAR FROM TO_DATE("txn_date", 'DD-MM-YYYY'))) 
      FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."BITCOIN_TRANSACTIONS"
    )
  GROUP BY m."region", EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY'))
) sub
ORDER BY sub."Year", "Rank";