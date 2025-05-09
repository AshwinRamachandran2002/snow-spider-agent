WITH max_comp_per_interest AS (  -- take the row with the highest composition for every interest  
    SELECT 
        im."interest_id",
        im."month_year",
        im."composition",
        ROW_NUMBER() OVER (
            PARTITION BY im."interest_id"
            ORDER BY im."composition" DESC NULLS LAST
        ) AS rn
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS im
    WHERE im."composition" IS NOT NULL
), best_comp AS (               -- join to the names of the interests  
    SELECT 
        mp."interest_name",
        mc."month_year",
        mc."composition"
    FROM max_comp_per_interest mc
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP mp
          ON mp."id" = mc."interest_id"
    WHERE mc.rn = 1              -- keep only the max-composition row per interest  
)

-- =====  Top 10 highest and Bottom 10 lowest (by their max composition)  =====
(   SELECT 
        bc."month_year"  AS "time(MM-YYYY)",
        bc."interest_name",
        bc."composition"
    FROM best_comp bc
    ORDER BY bc."composition" DESC NULLS LAST
    LIMIT 10
)
UNION ALL
(   SELECT 
        bc."month_year"  AS "time(MM-YYYY)",
        bc."interest_name",
        bc."composition"
    FROM best_comp bc
    ORDER BY bc."composition" ASC NULLS LAST
    LIMIT 10
);