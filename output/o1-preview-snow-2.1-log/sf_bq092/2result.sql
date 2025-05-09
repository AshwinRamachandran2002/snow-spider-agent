WITH received AS
(
    SELECT
        f.value::STRING AS "Address",
        t."type" AS "Type",
        SUM(t."value") AS total_received
    FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."OUTPUTS" t,
         LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1680307200000000  -- April 1, 2023
      AND t."block_timestamp" < 1682899200000000   -- May 1, 2023
    GROUP BY "Address", "Type"
),
spent AS
(
    SELECT
        f.value::STRING AS "Address",
        t."type" AS "Type",
        SUM(t."value") AS total_spent
    FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."INPUTS" t,
         LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" >= 1680307200000000  -- April 1, 2023
      AND t."block_timestamp" < 1682899200000000   -- May 1, 2023
    GROUP BY "Address", "Type"
),
net_changes AS
(
    SELECT
        COALESCE(received."Address", spent."Address") AS "Address",
        COALESCE(received."Type", spent."Type") AS "Type",
        ROUND(COALESCE(received.total_received, 0) - COALESCE(spent.total_spent, 0), 4) AS "NetChange"
    FROM received
    FULL OUTER JOIN spent
    ON received."Address" = spent."Address" AND received."Type" = spent."Type"
)
SELECT "Address", "Type", "NetChange"
FROM
(
    SELECT
        "Address", "Type", "NetChange",
        ROW_NUMBER() OVER (ORDER BY "NetChange" DESC NULLS LAST) AS rn_high,
        ROW_NUMBER() OVER (ORDER BY "NetChange" ASC NULLS FIRST) AS rn_low
    FROM net_changes
    WHERE "NetChange" IS NOT NULL
)
WHERE rn_high = 1 OR rn_low = 1
ORDER BY "NetChange" DESC NULLS LAST;