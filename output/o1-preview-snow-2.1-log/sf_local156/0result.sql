WITH avg_costs AS (
    SELECT
        m."region",
        EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')) AS "year",
        AVG(t."quantity" * p."price") AS "average_cost"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_MEMBERS m
      ON t."member_id" = m."member_id"
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_PRICES p
      ON TO_DATE(t."txn_date", 'DD-MM-YYYY') = TO_DATE(p."market_date", 'DD-MM-YYYY')
    WHERE t."txn_type" = 'BUY'
      AND EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY')) > (
        SELECT MIN(EXTRACT(YEAR FROM TO_DATE("txn_date", 'DD-MM-YYYY')))
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS
      )
    GROUP BY m."region", EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'DD-MM-YYYY'))
),
ranked_costs AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY "year" ORDER BY "average_cost" DESC NULLS LAST) AS "Rank",
        LAG("average_cost") OVER (PARTITION BY "region" ORDER BY "year") AS "prev_year_avg_cost"
    FROM avg_costs
),
final_result AS (
    SELECT
        "year" AS "Year",
        "region" AS "Region",
        ROUND("average_cost", 4) AS "Average_Purchase_Cost",
        "Rank",
        ROUND((( "average_cost" - "prev_year_avg_cost") / "prev_year_avg_cost") * 100, 4 ) AS "Annual_Percentage_Change"
    FROM ranked_costs
)
SELECT *
FROM final_result
ORDER BY "Year", "Rank";