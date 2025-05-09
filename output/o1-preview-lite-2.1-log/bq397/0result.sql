WITH country_counts AS (
    SELECT
        channelGrouping
    FROM `data-to-insights.ecommerce.all_sessions`
    GROUP BY channelGrouping
    HAVING COUNT(DISTINCT country) > 1
)

SELECT
    t.channelGrouping,
    t.country,
    t.total_transactions
FROM (
    SELECT
        channelGrouping,
        country,
        SUM(transactions) AS total_transactions,
        ROW_NUMBER() OVER (
            PARTITION BY channelGrouping
            ORDER BY SUM(transactions) DESC
        ) AS rn
    FROM `data-to-insights.ecommerce.all_sessions`
    WHERE channelGrouping IN (SELECT channelGrouping FROM country_counts)
    GROUP BY channelGrouping, country
) t
WHERE t.rn = 1;