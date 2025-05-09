WITH date_series AS (
    SELECT
        DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2017-01-01') AS "Date"
    FROM
        TABLE(GENERATOR(ROWCOUNT => 1827))  -- Number of days from 2017-01-01 to 2021-12-31 inclusive
),
user_contracts AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "Date",
        COUNT(*) AS "Contracts_Created_By_Users"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE
        "to_address" IS NULL
        AND "block_timestamp" >= 1483228800000000  -- '2017-01-01' in microseconds
        AND "block_timestamp" < 1640995200000000   -- '2022-01-01' in microseconds
    GROUP BY
        "Date"
),
contract_contracts AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ(t."block_timestamp" / 1e6)) AS "Date",
        COUNT(*) AS "Contracts_Created_By_Contracts"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRACES t
    JOIN
        CRYPTO.CRYPTO_ETHEREUM.CONTRACTS c
        ON t."from_address" = c."address"
    WHERE
        t."trace_type" = 'create'
        AND t."block_timestamp" >= 1483228800000000  -- '2017-01-01' in microseconds
        AND t."block_timestamp" < 1640995200000000   -- '2022-01-01' in microseconds
    GROUP BY
        "Date"
)
SELECT
    d."Date",
    SUM(COALESCE(u."Contracts_Created_By_Users", 0)) OVER (ORDER BY d."Date") AS "Cumulative_Contracts_Created_by_Users",
    SUM(COALESCE(c."Contracts_Created_By_Contracts", 0)) OVER (ORDER BY d."Date") AS "Cumulative_Contracts_Created_by_Contracts"
FROM
    date_series d
LEFT JOIN
    user_contracts u ON d."Date" = u."Date"
LEFT JOIN
    contract_contracts c ON d."Date" = c."Date"
ORDER BY
    d."Date";