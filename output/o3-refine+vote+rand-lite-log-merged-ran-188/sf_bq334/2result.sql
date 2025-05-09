WITH "IO_UNION" AS (
    /* merge INPUTS and OUTPUTS, keep flag to pick only OUTPUT records later */
    SELECT 'OUTPUT' AS "record_type",
           "block_timestamp",
           CAST("value" AS FLOAT) AS "val"
    FROM   CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT 'INPUT'  AS "record_type",
           "block_timestamp",
           CAST("value" AS FLOAT) AS "val"
    FROM   CRYPTO.CRYPTO_BITCOIN."INPUTS"
),
/* method 1 – yearly average from (merged) OUTPUT records                    */
"METHOD1" AS (
    SELECT TO_CHAR(TO_TIMESTAMP("block_timestamp"/1000000), 'YYYY') AS "year",
           AVG("val")                                               AS "avg_value_outputs"
    FROM   "IO_UNION"
    WHERE  "record_type" = 'OUTPUT'          -- keep only OUTPUT rows
    GROUP  BY "year"
),
/* method 2 – yearly average using TRANSACTIONS.output_value                */
"METHOD2" AS (
    SELECT TO_CHAR(TO_TIMESTAMP("block_timestamp"/1000000), 'YYYY') AS "year",
           AVG(CAST("output_value" AS FLOAT))                       AS "avg_value_transactions"
    FROM   CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP  BY "year"
)
/* join years present in both methods and calculate the difference          */
SELECT  m1."year",
        ROUND(m1."avg_value_outputs" - m2."avg_value_transactions", 4) 
        AS "difference_output_minus_txn"
FROM    "METHOD1" m1
JOIN    "METHOD2" m2
  ON    m1."year" = m2."year"
ORDER BY m1."year" NULLS LAST;