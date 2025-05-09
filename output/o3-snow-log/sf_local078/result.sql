WITH interest_max AS (   -- highest composition & its month for every interest
    SELECT 
        imt."interest_id",
        imt."month_year",
        imt."composition",
        ROW_NUMBER() OVER (
            PARTITION BY imt."interest_id" 
            ORDER BY imt."composition" DESC NULLS LAST, imt."month_year" ASC
        ) AS rn
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS" imt
),
interest_best AS (       -- keep only the record where composition is maximal
    SELECT 
        im."interest_name",
        imax."month_year",
        imax."composition"
    FROM interest_max imax
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP" im
          ON im."id" = imax."interest_id"
    WHERE imax.rn = 1
),
top10 AS (               -- 10 interests with the highest maxima
    SELECT 
        "month_year",
        "interest_name",
        "composition"
    FROM interest_best
    ORDER BY "composition" DESC NULLS LAST
    LIMIT 10
),
bottom10 AS (            -- 10 interests with the lowest maxima
    SELECT 
        "month_year",
        "interest_name",
        "composition"
    FROM interest_best
    ORDER BY "composition" ASC NULLS LAST
    LIMIT 10
)
SELECT 
    "month_year"     AS "TIME(MM-YYYY)",
    "interest_name"  AS "INTEREST_NAME",
    "composition"    AS "COMPOSITION_VALUE"
FROM top10
UNION ALL
SELECT 
    "month_year",
    "interest_name",
    "composition"
FROM bottom10;