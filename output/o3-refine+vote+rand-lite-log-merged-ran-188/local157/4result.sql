WITH parsed AS (
    /* 1. Keep 1-10 Aug 2021 rows and convert the “volume” text to a number  */
    SELECT
        "ticker",
        substr("market_date",7,4) || '-' || substr("market_date",4,2) || '-' ||
        substr("market_date",1,2)                      AS "date_iso",        -- ISO date
        CASE                                            -- convert volume text to a pure number
            WHEN "volume" = '-'          THEN 0
            WHEN "volume" LIKE '%K'      THEN CAST(REPLACE("volume",'K','') AS REAL) * 1000
            WHEN "volume" LIKE '%M'      THEN CAST(REPLACE("volume",'M','') AS REAL) * 1000000
            ELSE CAST("volume" AS REAL)
        END                                            AS "volume_numeric"
    FROM "bitcoin_prices"
    WHERE substr("market_date",4,7) = '08-2021'
      AND CAST(substr("market_date",1,2) AS INTEGER) BETWEEN 1 AND 10
),
prev_vol AS (
    /* 2. For every day, find that ticker’s latest previous NON-ZERO volume */
    SELECT
        p1."ticker",
        p1."date_iso",
        p1."volume_numeric"                                              AS "current_volume",
        (
            SELECT p2."volume_numeric"
            FROM   parsed p2
            WHERE  p2."ticker"         = p1."ticker"
              AND  p2."volume_numeric" > 0               -- only non-zero volumes
              AND  p2."date_iso"       < p1."date_iso"
            ORDER BY p2."date_iso" DESC
            LIMIT 1
        )                                                                AS "prev_volume"
    FROM parsed p1
)
SELECT
    "ticker",
    "date_iso"                                    AS "market_date",
    "current_volume",
    "prev_volume",
    CASE
        WHEN "prev_volume" IS NOT NULL
        THEN ROUND( ( "current_volume" - "prev_volume") * 100.0
                    / "prev_volume", 4 )
    END                                           AS "pct_change_vs_prev_non_zero_day(%)"
FROM prev_vol
ORDER BY "ticker", "market_date";