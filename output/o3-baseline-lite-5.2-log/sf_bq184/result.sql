WITH
/*------------------------------------------------------------------*
 | 1. calendar – one row per day from 2017‑01‑01 to 2021‑12‑31      |
 *------------------------------------------------------------------*/
dates AS (
    SELECT
        DATEADD(day, SEQ4(), DATE '2017-01-01') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 1826))     -- 1826 = 365+365+365+366+365
),
/*------------------------------------------------------------------*
 | 2. contract‑creation traces (Ethereum + Ethereum Classic)        |
 *------------------------------------------------------------------*/
creations AS (
    /* Ethereum */
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000))::DATE AS "date",
        CASE
            WHEN "trace_address" IS NULL OR TRIM("trace_address") = '' THEN 'external'
            ELSE 'contract'
        END AS "creator_type"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE LOWER("trace_type") IN ('create', 'create2')

    UNION ALL

    /* Ethereum Classic */
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1000000))::DATE,
        CASE
            WHEN "trace_address" IS NULL OR TRIM("trace_address") = '' THEN 'external'
            ELSE 'contract'
        END
    FROM CRYPTO.CRYPTO_ETHEREUM_CLASSIC.TRACES
    WHERE LOWER("trace_type") IN ('create', 'create2')
),
/*------------------------------------------------------------------*
 | 3. daily counts by creator category                              |
 *------------------------------------------------------------------*/
daily AS (
    SELECT
        "date",
        "creator_type",
        COUNT(*) AS daily_count
    FROM creations
    GROUP BY 1, 2
),
/*------------------------------------------------------------------*
 | 4. calendar left‑join to include zero‑creation days              |
 *------------------------------------------------------------------*/
daily_pivot AS (
    SELECT
        d."date",
        COALESCE(SUM(CASE WHEN dl."creator_type" = 'external' THEN dl.daily_count END), 0) AS new_external,
        COALESCE(SUM(CASE WHEN dl."creator_type" = 'contract' THEN dl.daily_count END), 0) AS new_contract
    FROM dates d
    LEFT JOIN daily dl
      ON d."date" = dl."date"
    GROUP BY d."date"
),
/*------------------------------------------------------------------*
 | 5. cumulative (monotonically increasing) totals                  |
 *------------------------------------------------------------------*/
cum AS (
    SELECT
        "date",
        SUM(new_external) OVER (ORDER BY "date") AS cumulative_external,
        SUM(new_contract) OVER (ORDER BY "date") AS cumulative_contract
    FROM daily_pivot
)
/*------------------------------------------------------------------*
 | 6. final output                                                  |
 *------------------------------------------------------------------*/
SELECT
    "date",
    cumulative_external,
    cumulative_contract
FROM cum
ORDER BY "date";