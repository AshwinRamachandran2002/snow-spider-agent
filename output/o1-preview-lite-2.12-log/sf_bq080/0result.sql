SELECT
    "Date",
    SUM("User_Created_Contracts") OVER (ORDER BY "Date" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Cumulative_User_Created_Contracts",
    SUM("Contract_Created_Contracts") OVER (ORDER BY "Date" ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Cumulative_Contract_Created_Contracts"
FROM
(
    SELECT
        DATE(TO_TIMESTAMP(t."block_timestamp" / 1000000)) AS "Date",
        COUNT(CASE WHEN c."address" IS NULL THEN 1 END) AS "User_Created_Contracts",
        COUNT(CASE WHEN c."address" IS NOT NULL THEN 1 END) AS "Contract_Created_Contracts"
    FROM
        "CRYPTO"."CRYPTO_ETHEREUM"."TRACES" t
    LEFT JOIN
        "CRYPTO"."CRYPTO_ETHEREUM"."CONTRACTS" c
    ON
        t."from_address" = c."address"
    WHERE
        t."trace_type" = 'create'
        AND t."block_timestamp" >= 1535587200000000  -- August 30, 2018
        AND t."block_timestamp" <= 1538351999000000  -- September 30, 2018
    GROUP BY
        "Date"
)
ORDER BY
    "Date";