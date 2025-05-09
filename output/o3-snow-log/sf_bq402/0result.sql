WITH "VISITOR_TXNS" AS (
    /* aggregate every visitor’s total number of transactions across all of
       their sessions (the “totals” column is a VARIANT that contains
       the JSON key  "transactions")                                        */
    SELECT
        "fullVisitorId"                                               AS "VISITOR_ID",
        SUM( COALESCE( "totals":"transactions"::NUMBER , 0) )         AS "TOTAL_TRANSACTIONS"
    FROM   ECOMMERCE.ECOMMERCE.WEB_ANALYTICS
    GROUP  BY "fullVisitorId"
)

SELECT
    COUNT(*)                                                         AS "TOTAL_UNIQUE_VISITORS",
    COUNT_IF("TOTAL_TRANSACTIONS" > 0)                               AS "UNIQUE_PURCHASERS",
    ROUND( COUNT_IF("TOTAL_TRANSACTIONS" > 0)::FLOAT
           / COUNT(*)
         , 4)                                                        AS "CONVERSION_RATE",
    ROUND( AVG( CASE WHEN "TOTAL_TRANSACTIONS" > 0
                     THEN "TOTAL_TRANSACTIONS" END )
         , 4)                                                        AS "AVG_TRANSACTIONS_PER_PURCHASER"
FROM   "VISITOR_TXNS";