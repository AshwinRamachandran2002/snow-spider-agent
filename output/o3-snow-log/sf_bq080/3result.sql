WITH
/* 1) Calendar table containing every day from 2018-08-30 to 2018-09-30 (32 days) */
"dates" AS (
    SELECT
        DATEADD(day, SEQ4(), '2018-08-30'::DATE) AS "DATE"
    FROM TABLE(
        GENERATOR(ROWCOUNT => 32)   -- 31-day difference + 1 for inclusive range
    )
),

/* 2) Daily counts of contract-creation traces split by creator type               */
"creations" AS (
    SELECT
        CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE) AS "DATE",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = '' THEN 'external'
            ELSE 'contract'
        END                                                         AS "creator_type",
        COUNT(*)                                                    AS "cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND CAST(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000) AS DATE)
            BETWEEN '2018-08-30' AND '2018-09-30'
    GROUP BY 1, 2
),

/* 3) Pivot the daily counts                                                      */
"pivoted" AS (
    SELECT
        "DATE",
        COALESCE(MAX(CASE WHEN "creator_type" = 'external'  THEN "cnt" END), 0) AS "external_daily",
        COALESCE(MAX(CASE WHEN "creator_type" = 'contract' THEN "cnt" END), 0) AS "contract_daily"
    FROM "creations"
    GROUP BY "DATE"
),

/* 4) Join to calendar to guarantee every date appears                            */
"daily" AS (
    SELECT
        d."DATE",
        COALESCE(p."external_daily", 0)  AS "external_daily",
        COALESCE(p."contract_daily", 0)  AS "contract_daily"
    FROM "dates" d
    LEFT JOIN "pivoted" p
           ON d."DATE" = p."DATE"
),

/* 5) Cumulative running totals                                                   */
"cumulative" AS (
    SELECT
        "DATE",
        SUM("external_daily")  OVER (ORDER BY "DATE") AS "cumulative_external",
        SUM("contract_daily")  OVER (ORDER BY "DATE") AS "cumulative_contract"
    FROM "daily"
)

/* 6) Final result                                                                */
SELECT
    "DATE",
    "cumulative_external",
    "cumulative_contract"
FROM "cumulative"
ORDER BY "DATE";