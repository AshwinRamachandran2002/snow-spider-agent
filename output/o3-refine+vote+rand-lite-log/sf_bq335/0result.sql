WITH unified AS (
    /* --- INPUTS --- */
    SELECT
        addr.value::STRING                        AS "ADDRESS",
        "value"                                   AS "AMOUNT",
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS "TS"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
         ,LATERAL FLATTEN(INPUT => "addresses") addr

    UNION ALL

    /* --- OUTPUTS --- */
    SELECT
        addr.value::STRING                        AS "ADDRESS",
        "value"                                   AS "AMOUNT",
        TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS "TS"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
         ,LATERAL FLATTEN(INPUT => "addresses") addr
),
october_tx AS (
    SELECT *
    FROM unified
    WHERE "TS" >= '2017-10-01'::DATE
      AND "TS" <  '2017-11-01'::DATE
),
per_address AS (
    SELECT
        "ADDRESS",
        MAX(CAST("TS" AS DATE))        AS "LAST_DATE",
        SUM("AMOUNT")                  AS "TOTAL_AMOUNT"
    FROM october_tx
    GROUP BY "ADDRESS"
),
max_date AS (
    SELECT MAX("LAST_DATE") AS "LATEST_DATE"
    FROM   per_address
)
SELECT
    p."ADDRESS",
    p."LAST_DATE",
    p."TOTAL_AMOUNT"
FROM per_address p
JOIN max_date   d
  ON p."LAST_DATE" = d."LATEST_DATE"
ORDER BY
    p."TOTAL_AMOUNT" DESC NULLS LAST,
    p."ADDRESS"      ASC
FETCH FIRST 1 ROWS ONLY;