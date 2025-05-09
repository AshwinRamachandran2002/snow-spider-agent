WITH unique_transactions AS (
    SELECT DISTINCT
        hits_transaction_transactionId,
        channelGrouping,
        geoNetwork_country
    FROM
        `data-to-insights.ecommerce.rev_transactions`
    WHERE
        hits_transaction_transactionId IS NOT NULL
            AND hits_transaction_transactionId != ''
            AND channelGrouping IS NOT NULL
            AND channelGrouping != ''
            AND geoNetwork_country IS NOT NULL
            AND geoNetwork_country != ''
    ),
channel_groupings_multi_country AS (
    SELECT
        channelGrouping
    FROM
        unique_transactions
    GROUP BY
        channelGrouping
    HAVING
        COUNT(DISTINCT geoNetwork_country) > 1
    ),
transactions_per_country AS (
    SELECT
        channelGrouping,
        geoNetwork_country AS country,
        COUNT(*) AS total_transactions
    FROM
        unique_transactions
    WHERE
        channelGrouping IN (SELECT channelGrouping FROM channel_groupings_multi_country)
    GROUP BY
        channelGrouping,
        country
    ),
top_countries AS (
    SELECT
        channelGrouping,
        country,
        total_transactions,
        ROW_NUMBER() OVER (PARTITION BY channelGrouping ORDER BY total_transactions DESC) AS rn
    FROM
        transactions_per_country
)
SELECT
    channelGrouping,
    country,
    total_transactions
FROM
    top_countries
WHERE
    rn = 1
ORDER BY
    channelGrouping