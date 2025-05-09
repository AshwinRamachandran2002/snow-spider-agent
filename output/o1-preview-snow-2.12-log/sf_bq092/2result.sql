WITH credits AS (
    SELECT f.value::string AS "Address", SUM(t."value"::float) AS "Total_Credit"
    FROM "CRYPTO"."CRYPTO_DASH"."OUTPUTS" t
    , LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1680307200000000 AND t."block_timestamp" < 1682899200000000
    GROUP BY f.value::string
),
debits AS (
    SELECT f.value::string AS "Address", SUM(t."value"::float) AS "Total_Debit"
    FROM "CRYPTO"."CRYPTO_DASH"."INPUTS" t
    , LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1680307200000000 AND t."block_timestamp" < 1682899200000000
    GROUP BY f.value::string
),
net_changes AS (
    SELECT
        COALESCE(credits."Address", debits."Address") AS "Address",
        COALESCE(credits."Total_Credit", 0) - COALESCE(debits."Total_Debit", 0) AS "Resulting_Balance"
    FROM credits
    FULL OUTER JOIN debits ON credits."Address" = debits."Address"
),
max_balance AS (
    SELECT "Address", ROUND("Resulting_Balance", 4) AS "Resulting_Balance"
    FROM net_changes
    ORDER BY "Resulting_Balance" DESC NULLS LAST
    LIMIT 1
),
min_balance AS (
    SELECT "Address", ROUND("Resulting_Balance", 4) AS "Resulting_Balance"
    FROM net_changes
    ORDER BY "Resulting_Balance" ASC NULLS LAST
    LIMIT 1
)
SELECT "Address", "Resulting_Balance"
FROM max_balance
UNION ALL
SELECT "Address", "Resulting_Balance"
FROM min_balance;