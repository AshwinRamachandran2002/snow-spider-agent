WITH received AS (
    SELECT 
        f.value::STRING AS "Address",
        t."type" AS "Type",
        SUM(t."value") AS "TotalReceived"
    FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."OUTPUTS" t,
    LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" BETWEEN 1680307200000000 AND 1682899199000000
    GROUP BY "Address", "Type"
),
sent AS (
    SELECT 
        f.value::STRING AS "Address",
        t."type" AS "Type",
        SUM(t."value") AS "TotalSent"
    FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."INPUTS" t,
    LATERAL FLATTEN(input => t."addresses") f
    WHERE t."block_timestamp" BETWEEN 1680307200000000 AND 1682899199000000
    GROUP BY "Address", "Type"
),
net_changes AS (
    SELECT
        COALESCE(r."Address", s."Address") AS "Address",
        COALESCE(r."Type", s."Type") AS "Type",
        ROUND(COALESCE(r."TotalReceived", 0) - COALESCE(s."TotalSent", 0), 4) AS "NetChange"
    FROM received r
    FULL OUTER JOIN sent s ON r."Address" = s."Address" AND r."Type" = s."Type"
),
ranked_net_changes AS (
    SELECT
        "Address",
        "Type",
        "NetChange",
        ROW_NUMBER() OVER (ORDER BY "NetChange" DESC NULLS LAST) AS rn_desc,
        ROW_NUMBER() OVER (ORDER BY "NetChange" ASC NULLS LAST) AS rn_asc
    FROM net_changes
)
SELECT "Address", "Type", "NetChange"
FROM ranked_net_changes
WHERE rn_desc = 1 OR rn_asc = 1;