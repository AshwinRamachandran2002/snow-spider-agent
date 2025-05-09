/*  Step-by-step logic
    1.   Bring the data to visit level so every visit is counted only once
         even if it appears in several product rows.
    2.   Aggregate transactions by channel-country.
    3.   Keep only the channel groupings that have transactions
         coming from more than one country.
    4.   For every such channel grouping pick the country that
         contributes the most transactions.
*/

WITH visit_level AS (          -- 1. de-duplicate to visit level
    SELECT
        "channelGrouping",
        "geoNetwork_country"      AS country,
        "visitId",
        MAX("totals_transactions") AS visit_transactions
    FROM ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE "totals_transactions" IS NOT NULL
    GROUP BY
        "channelGrouping",
        "geoNetwork_country",
        "visitId"
),

channel_country AS (           -- 2. sum transactions per channel & country
    SELECT
        "channelGrouping",
        country,
        SUM(visit_transactions)  AS total_transactions
    FROM visit_level
    GROUP BY
        "channelGrouping",
        country
),

eligible_channels AS (         -- 3. channels present in >1 country
    SELECT
        "channelGrouping"
    FROM channel_country
    GROUP BY "channelGrouping"
    HAVING COUNT(DISTINCT country) > 1
),

ranked AS (                     -- 4. rank countries inside every channel
    SELECT
        cc."channelGrouping",
        cc.country,
        cc.total_transactions,
        ROW_NUMBER() OVER (
            PARTITION BY cc."channelGrouping"
            ORDER BY cc.total_transactions DESC, cc.country
        ) AS rn
    FROM channel_country cc
    JOIN eligible_channels ec
      ON cc."channelGrouping" = ec."channelGrouping"
)

SELECT
    "channelGrouping",
    country,
    total_transactions
FROM ranked
WHERE rn = 1                    -- take top country per channel
ORDER BY "channelGrouping";