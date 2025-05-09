WITH
-- 1. calendar covering every day in the required period (2017‑01‑01‑‑2021‑12‑31 = 1 826 days)
dates AS (
    SELECT
        DATEADD(
            day,
            SEQ4(),
            TO_DATE('2017-01-01')
        ) AS "DT"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 1826)   -- constant rowcount required
    )
),

-- 2. contract‑creation traces from Ethereum + Ethereum Classic
creations AS (
    SELECT
        /* convert micro‑seconds to TIMESTAMP, then to UTC DATE */
        TO_DATE(
            CONVERT_TIMEZONE(
                'UTC',
                TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)
            )
        )                                                     AS "DT",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 'external'
            ELSE 'contract'
        END                                                   AS "CREATOR_TYPE",
        COUNT(*)                                              AS "CNT"
    FROM (
        /* Ethereum traces */
        SELECT
            "block_timestamp",
            "trace_address",
            LOWER("trace_type") AS "trace_type",
            "status"
        FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"

        UNION ALL

        /* Ethereum Classic traces */
        SELECT
            "block_timestamp",
            "trace_address",
            LOWER("trace_type") AS "trace_type",
            "status"
        FROM "CRYPTO"."CRYPTO_ETHEREUM_CLASSIC"."TRACES"
    ) t
    WHERE
        "trace_type" = 'create'                -- contract‑creation traces
        AND "status" = 1                       -- successful only
        AND TO_DATE(
                CONVERT_TIMEZONE(
                    'UTC',
                    TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)
                )
            ) BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY
        "DT",
        "CREATOR_TYPE"
),

-- 3. cartesian calendar × creator_type, ensuring every date/category is present
calendar AS (
    SELECT
        d."DT",
        c."CREATOR_TYPE"
    FROM dates d
    CROSS JOIN (
        SELECT 'external' AS "CREATOR_TYPE"
        UNION ALL
        SELECT 'contract'
    ) c
),

-- 4. daily counts (0 when no creations that day)
daily AS (
    SELECT
        cal."DT",
        cal."CREATOR_TYPE",
        COALESCE(cr."CNT", 0) AS "CNT"
    FROM calendar cal
    LEFT JOIN creations cr
        ON  cal."DT"           = cr."DT"
        AND cal."CREATOR_TYPE" = cr."CREATOR_TYPE"
),

-- 5. cumulative totals per category
cum AS (
    SELECT
        "DT",
        "CREATOR_TYPE",
        SUM("CNT") OVER (
            PARTITION BY "CREATOR_TYPE"
            ORDER BY "DT"
        ) AS "CUM_CNT"
    FROM daily
)

-- 6. pivot to one row per day with two cumulative columns
SELECT
    "DT"                                                                 AS "DATE",
    MAX(CASE WHEN "CREATOR_TYPE" = 'external'  THEN "CUM_CNT" END)       AS "CUM_EXTERNAL_CREATIONS",
    MAX(CASE WHEN "CREATOR_TYPE" = 'contract' THEN "CUM_CNT" END)        AS "CUM_CONTRACT_CREATIONS"
FROM cum
GROUP BY "DT"
ORDER BY "DT";