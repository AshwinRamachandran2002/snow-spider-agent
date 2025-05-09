WITH date_range AS (                                               
    SELECT DATEADD(day, seq4(), TO_DATE('2018-08-30')) AS "event_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
daily AS (                                                          
    SELECT
        TO_DATE(TO_TIMESTAMP_LTZ("block_timestamp" / 1000000))             AS "event_date",
        CASE WHEN "trace_address" IS NULL THEN 'EOA' ELSE 'INTERNAL' END    AS "creator_type",
        COUNT(*)                                                           AS "daily_cnt"
    FROM "CRYPTO"."CRYPTO_ETHEREUM"."TRACES"
    WHERE "trace_type"     = 'create'
      AND "status"         = 1                                            
      AND "block_timestamp" BETWEEN 1535587200000000   
                              AND 1538351999999999   
    GROUP BY 1,2
),
expanded AS (                                                      
    SELECT
        dr."event_date",
        COALESCE(eoa."daily_cnt", 0)   AS "daily_eoa",
        COALESCE(intr."daily_cnt", 0)  AS "daily_internal"
    FROM date_range dr
    LEFT JOIN daily eoa  ON dr."event_date" = eoa."event_date"  AND eoa."creator_type" = 'EOA'
    LEFT JOIN daily intr ON dr."event_date" = intr."event_date" AND intr."creator_type" = 'INTERNAL'
)
SELECT
    "event_date"                                                    AS "date",
    SUM("daily_eoa")      OVER (ORDER BY "event_date")              AS "cumulative_eoa_contracts",
    SUM("daily_internal") OVER (ORDER BY "event_date")              AS "cumulative_internal_contracts"
FROM expanded
ORDER BY "event_date";