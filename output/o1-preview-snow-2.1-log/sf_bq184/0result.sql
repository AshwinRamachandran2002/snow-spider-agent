WITH dates AS (
    SELECT
        DATEADD('day', ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2017-01-01') AS "Date"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)
    )
),
contracts_created_by_users AS (
    SELECT
        TO_DATE(TO_TIMESTAMP(t."block_timestamp"::NUMBER / 1000000)) AS "Date",
        COUNT(*) AS "Contracts_Created_by_Users"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS t
    LEFT JOIN
        CRYPTO.CRYPTO_ETHEREUM.CONTRACTS c
    ON
        t."from_address" = c."address"
    WHERE
        ("to_address" IS NULL OR "to_address" = '')
        AND c."address" IS NULL  -- Exclude if from_address is a contract
        AND TO_DATE(TO_TIMESTAMP(t."block_timestamp"::NUMBER / 1000000)) BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY
        "Date"
),
contracts_created_by_contracts AS (
    SELECT
        TO_DATE(TO_TIMESTAMP(tr."block_timestamp"::NUMBER / 1000000)) AS "Date",
        COUNT(*) AS "Contracts_Created_by_Contracts"
    FROM
        CRYPTO.CRYPTO_ETHEREUM.TRACES tr
    INNER JOIN
        CRYPTO.CRYPTO_ETHEREUM.CONTRACTS c
    ON
        tr."from_address" = c."address"
    WHERE
        tr."trace_type" = 'create'
        AND TO_DATE(TO_TIMESTAMP(tr."block_timestamp"::NUMBER / 1000000)) BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY
        "Date"
)
SELECT
    d."Date",
    SUM(COALESCE(cu."Contracts_Created_by_Users", 0)) OVER (ORDER BY d."Date") AS "Cumulative_Contracts_Created_by_Users",
    SUM(COALESCE(cc."Contracts_Created_by_Contracts", 0)) OVER (ORDER BY d."Date") AS "Cumulative_Contracts_Created_by_Contracts"
FROM
    dates d
LEFT JOIN
    contracts_created_by_users cu ON d."Date" = cu."Date"
LEFT JOIN
    contracts_created_by_contracts cc ON d."Date" = cc."Date"
ORDER BY
    d."Date";