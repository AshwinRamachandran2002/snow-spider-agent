WITH dates AS (
    SELECT
        DATEADD(day, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2018-08-30'::DATE) AS "Date"
    FROM
        TABLE(GENERATOR(ROWCOUNT => 32))  -- 32 days from '2018-08-30' to '2018-09-30' inclusive
),
user_contracts AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP(t."block_timestamp" / 1e6)) AS "Date",
        COUNT(*) AS "User_Contracts_Created"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    LEFT JOIN
        CRYPTO.CRYPTO_ETHEREUM.CONTRACTS c ON t."from_address" = c."address"
    WHERE
        t."receipt_contract_address" IS NOT NULL
        AND c."address" IS NULL  -- from_address is not a contract
        AND DATE_TRUNC('day', TO_TIMESTAMP(t."block_timestamp" / 1e6)) BETWEEN '2018-08-30'::DATE AND '2018-09-30'::DATE
    GROUP BY
        "Date"
),
contract_contracts AS (
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP(tr."block_timestamp" / 1e6)) AS "Date",
        COUNT(*) AS "Contract_Contracts_Created"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    INNER JOIN
        CRYPTO.CRYPTO_ETHEREUM.CONTRACTS c ON tr."from_address" = c."address"
    WHERE
        tr."trace_type" = 'create'
        AND DATE_TRUNC('day', TO_TIMESTAMP(tr."block_timestamp" / 1e6)) BETWEEN '2018-08-30'::DATE AND '2018-09-30'::DATE
    GROUP BY
        "Date"
),
daily_counts AS (
    SELECT
        d."Date",
        COALESCE(u."User_Contracts_Created", 0) AS "User_Contracts_Created",
        COALESCE(c."Contract_Contracts_Created", 0) AS "Contract_Contracts_Created"
    FROM
        dates d
    LEFT JOIN
        user_contracts u ON d."Date" = u."Date"
    LEFT JOIN
        contract_contracts c ON d."Date" = c."Date"
),
cumulative_counts AS (
    SELECT
        "Date",
        SUM("User_Contracts_Created") OVER (ORDER BY "Date") AS "Cumulative_User_Created_Contracts",
        SUM("Contract_Contracts_Created") OVER (ORDER BY "Date") AS "Cumulative_Contract_Created_Contracts"
    FROM
        daily_counts
)
SELECT
    TO_CHAR("Date", 'YYYY-MM-DD') AS "Date",
    "Cumulative_User_Created_Contracts",
    "Cumulative_Contract_Created_Contracts"
FROM
    cumulative_counts
ORDER BY
    "Date";