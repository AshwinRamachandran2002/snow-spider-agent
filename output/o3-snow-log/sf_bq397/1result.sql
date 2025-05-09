/*  Step-1 :  De-duplicate the REV_TRANSACTIONS data set                     */
/*           – one record per (visitId , transactionId , country , channel)  */
WITH dedup AS (       
    SELECT DISTINCT
           "visitId",
           "hits_transaction_transactionId"          AS "transactionId",
           "channelGrouping",
           "geoNetwork_country"                      AS "country",
           COALESCE("totals_transactions",0)         AS "transactions"
    FROM   ECOMMERCE.ECOMMERCE.REV_TRANSACTIONS
    WHERE  "totals_transactions" IS NOT NULL
),

/*  Step-2 :  Aggregate transactions per (channelGrouping , country)          */
country_totals AS (    
    SELECT  "channelGrouping",
            "country",
            SUM("transactions")                     AS "total_transactions"
    FROM    dedup
    GROUP BY "channelGrouping","country"
),

/*  Step-3 :  Keep only those channelGroupings that appear in > 1 country     */
multi_country_channels AS (
    SELECT  "channelGrouping"
    FROM    country_totals
    GROUP BY "channelGrouping"
    HAVING  COUNT(DISTINCT "country") > 1
),

/*  Step-4 :  For each remaining channelGrouping, pick the top-country        */
ranked AS (    
    SELECT  ct."channelGrouping",
            ct."country",
            ct."total_transactions",
            ROW_NUMBER() OVER (PARTITION BY ct."channelGrouping"
                               ORDER BY ct."total_transactions" DESC NULLS LAST,
                                        ct."country")               AS rn
    FROM    country_totals ct
    JOIN    multi_country_channels mc
           ON ct."channelGrouping" = mc."channelGrouping"
)

/*  Final result : one row per channelGrouping with its top country           */
SELECT  "channelGrouping",
        "country",
        "total_transactions"
FROM    ranked
WHERE   rn = 1
ORDER BY "channelGrouping";