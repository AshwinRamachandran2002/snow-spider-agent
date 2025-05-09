WITH yearly_data AS (
  SELECT
    substr(t."txn_date", 7, 4) AS "Year",
    m."region" AS "Region",
    AVG(t."quantity" * p."price") AS "Average_Cost"
  FROM "bitcoin_transactions" t
  JOIN "bitcoin_members" m ON t."member_id" = m."member_id"
  JOIN "bitcoin_prices" p ON t."ticker" = p."ticker" AND t."txn_date" = p."market_date"
  WHERE t."txn_type" = 'BUY'
    AND substr(t."txn_date", 7, 4) <> (
      SELECT MIN(substr("txn_date", 7, 4)) FROM "bitcoin_transactions"
    )
  GROUP BY "Year", "Region"
)
SELECT
  yd."Year",
  yd."Region",
  ROUND(yd."Average_Cost", 4) AS "Average_Cost",
  DENSE_RANK() OVER (PARTITION BY yd."Year" ORDER BY yd."Average_Cost" DESC) AS "Rank",
  ROUND(
    100.0 * (yd."Average_Cost" - LAG(yd."Average_Cost") OVER (PARTITION BY yd."Region" ORDER BY yd."Year"))
    / LAG(yd."Average_Cost") OVER (PARTITION BY yd."Region" ORDER BY yd."Year"),
    4
  ) AS "Annual_Percentage_Change"
FROM yearly_data yd
ORDER BY yd."Year", "Rank";