WITH transactions_table AS (
    SELECT
        "channelGrouping",
        "country",
        SUM("transactions") AS "total_transactions"
    FROM ECOMMERCE.ECOMMERCE.ALL_SESSIONS
    WHERE "transactions" > 0
    GROUP BY "channelGrouping", "country"
),
channel_country_counts AS (
    SELECT
        "channelGrouping",
        COUNT(DISTINCT "country") AS "country_count"
    FROM transactions_table
    GROUP BY "channelGrouping"
),
transactions_with_rn AS (
    SELECT
        tt.*,
        ROW_NUMBER() OVER (
            PARTITION BY tt."channelGrouping" 
            ORDER BY tt."total_transactions" DESC NULLS LAST
        ) AS rn
    FROM transactions_table tt
    JOIN channel_country_counts ccc
        ON tt."channelGrouping" = ccc."channelGrouping"
    WHERE ccc."country_count" > 1
)
SELECT
    "channelGrouping" AS "Channel_Grouping",
    "country" AS "Country",
    "total_transactions" AS "Total_Transactions"
FROM transactions_with_rn
WHERE rn = 1
ORDER BY "Channel_Grouping" ASC NULLS LAST;