WITH trace_creations AS (
    /* all contract‑creation traces during the requested period */
    SELECT
        /* convert micro‑seconds to TIMESTAMP, then take UTC date */
        TO_TIMESTAMP("block_timestamp" / 1e6)::DATE                     AS "DATE",
        CASE
            /* top‑level create ⇒ created by an externally‑owned account */
            WHEN "trace_address" IS NULL
              OR TRIM("trace_address") IN ('', '0') THEN 'EXTERNAL'
            /* otherwise the create was issued from another contract       */
            ELSE 'CONTRACT'
        END                                                             AS "CREATOR_TYPE"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_TIMESTAMP("block_timestamp" / 1e6)::DATE
            BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
),
daily_counts AS (
    /* number of new contracts per day, split by creator type            */
    SELECT
        "DATE",
        SUM(CASE WHEN "CREATOR_TYPE" = 'EXTERNAL'  THEN 1 ELSE 0 END)   AS "EXT_CREATED",
        SUM(CASE WHEN "CREATOR_TYPE" = 'CONTRACT' THEN 1 ELSE 0 END)    AS "CTR_CREATED"
    FROM trace_creations
    GROUP BY "DATE"
),
calendar AS (
    /* every calendar day in the requested range                          */
    SELECT
        DATEADD(day, seq4(), DATE '2018-08-30') AS "DATE"
    FROM TABLE(GENERATOR(ROWCOUNT => 40))              -- 32 days needed, 40 is safe
    WHERE DATEADD(day, seq4(), DATE '2018-08-30') <= DATE '2018-09-30'
),
combined AS (
    /* join calendar with actual counts, filling missing days with zeros  */
    SELECT
        c."DATE",
        COALESCE(d."EXT_CREATED", 0)  AS "EXT_CREATED",
        COALESCE(d."CTR_CREATED", 0)  AS "CTR_CREATED"
    FROM calendar c
    LEFT JOIN daily_counts d USING ("DATE")
)
SELECT
    "DATE",
    /* running totals must be strictly non‑decreasing                     */
    SUM("EXT_CREATED") OVER (ORDER BY "DATE")  AS "CUM_EXTERNAL_CREATIONS",
    SUM("CTR_CREATED") OVER (ORDER BY "DATE")  AS "CUM_CONTRACT_CREATIONS"
FROM combined
ORDER BY "DATE";