/* 1.  Deduplicate the REV_TRANSACTIONS table at the session level
       (visitId) so each transaction is counted only once.          */
WITH distinct_sessions AS (
    SELECT DISTINCT
           "channelGrouping",
           "geoNetwork_country"      AS "country",
           "visitId",                         -- unique session / transaction
           COALESCE("totals_transactions",0) AS "transactions"
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "totals_transactions" IS NOT NULL
),

/* 2.  Aggregate total transactions by Channel Grouping and Country. */
agg AS (
    SELECT
           "channelGrouping",
           "country",
           SUM("transactions") AS total_transactions
    FROM   distinct_sessions
    GROUP  BY "channelGrouping",
             "country"
),

/* 3.  Keep only channel groupings that appear in more than one country. */
multi_country_channels AS (
    SELECT  "channelGrouping"
    FROM    agg
    GROUP   BY "channelGrouping"
    HAVING  COUNT(DISTINCT "country") > 1
),

/* 4.  Rank countries inside each qualifying channel grouping
       by their total number of transactions (largest first).       */
ranked AS (
    SELECT
           a."channelGrouping",
           a."country",
           a.total_transactions,
           ROW_NUMBER() OVER (PARTITION BY a."channelGrouping"
                              ORDER BY a.total_transactions DESC, a."country") AS rn
    FROM   agg a
    JOIN   multi_country_channels mc
        ON a."channelGrouping" = mc."channelGrouping"
)

/* 5.  Return the top-transaction country for every such channel grouping. */
SELECT  "channelGrouping",
        "country",
        total_transactions
FROM    ranked
WHERE   rn = 1
ORDER BY "channelGrouping";