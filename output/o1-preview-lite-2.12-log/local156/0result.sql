SELECT 
    ac."Year", 
    ac."Region",
    ac."Average_Cost",
    RANK() OVER (PARTITION BY ac."Year" ORDER BY ac."Average_Cost" DESC) AS "Rank",
    ROUND(
        ((ac."Average_Cost" - LAG(ac."Average_Cost") OVER (
            PARTITION BY ac."Region" ORDER BY CAST(ac."Year" AS INTEGER)
        )) / LAG(ac."Average_Cost") OVER (
            PARTITION BY ac."Region" ORDER BY CAST(ac."Year" AS INTEGER)
        )) * 100
    , 4) AS "Annual_Percentage_Change"
FROM (
    SELECT
        SUBSTR(t."txn_date", -4, 4) AS "Year",
        m."region" AS "Region",
        AVG(t."quantity" * p."price") AS "Average_Cost"
    FROM "bitcoin_transactions" AS t
    JOIN "bitcoin_members" AS m
        ON t."member_id" = m."member_id"
    JOIN "bitcoin_prices" AS p
        ON t."ticker" = p."ticker"
        AND t."txn_date" = p."market_date"
    WHERE t."txn_type" = 'BUY'
      AND CAST(SUBSTR(t."txn_date", -4, 4) AS INTEGER) > (
          SELECT MIN(CAST(SUBSTR("txn_date", -4, 4) AS INTEGER))
          FROM "bitcoin_transactions"
      )
    GROUP BY "Year", "Region"
) AS ac
ORDER BY ac."Year", "Rank";