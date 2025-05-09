WITH "CALENDAR" AS (
    -- 32-day calendar from 30-Aug-2018 through 30-Sep-2018 (inclusive)
    SELECT
        DATEADD(day, seq4(), '2018-08-30') AS "DAY_DATE"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
"DAILY_CREATIONS" AS (
    -- Daily counts of contract-creation traces inside the target window
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))         AS "DAY_DATE",
        COUNT_IF("trace_address" IS NULL)                                AS "EXT_USER_CREATIONS",
        COUNT_IF("trace_address" IS NOT NULL)                            AS "CONTRACT_CREATIONS"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "block_timestamp" BETWEEN 1535587200000000   -- 30-Aug-2018 00:00:00 UTC
                              AND 1538351999000000     -- 30-Sep-2018 23:59:59 UTC
    GROUP BY 1
),
"MERGED" AS (
    -- Join calendar with daily counts, filling missing days with zeros
    SELECT
        c."DAY_DATE",
        COALESCE(d."EXT_USER_CREATIONS",     0) AS "EXT_DAY",
        COALESCE(d."CONTRACT_CREATIONS",     0) AS "CTR_DAY"
    FROM "CALENDAR"          c
    LEFT JOIN "DAILY_CREATIONS" d
           ON c."DAY_DATE" = d."DAY_DATE"
)
-- Cumulative (running) totals, ensuring non-decreasing series
SELECT
    "DAY_DATE"                                           AS "DATE",
    SUM("EXT_DAY") OVER (ORDER BY "DAY_DATE")            AS "CUM_EXTERNAL_CREATIONS",
    SUM("CTR_DAY") OVER (ORDER BY "DAY_DATE")            AS "CUM_CONTRACT_CREATIONS"
FROM "MERGED"
ORDER BY "DAY_DATE";