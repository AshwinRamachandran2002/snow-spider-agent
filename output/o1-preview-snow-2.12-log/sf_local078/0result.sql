WITH MaxCompositions AS (
    SELECT
        im."interest_id",
        im."month_year" AS "Time",
        m."interest_name" AS "Interest Name",
        ROUND(im."composition", 4) AS "Composition Value",
        ROW_NUMBER() OVER (PARTITION BY im."interest_id" ORDER BY im."composition" DESC NULLS LAST, im."month_year") AS rn
    FROM 
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS" im
    JOIN 
        "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" m
            ON im."interest_id" = m."id"
    WHERE im."composition" IS NOT NULL
)
SELECT "Time", "Interest Name", "Composition Value"
FROM (
    SELECT "Time", "Interest Name", "Composition Value",
        ROW_NUMBER() OVER (ORDER BY "Composition Value" DESC NULLS LAST, "Interest Name") AS rank_desc,
        ROW_NUMBER() OVER (ORDER BY "Composition Value" ASC NULLS LAST, "Interest Name") AS rank_asc
    FROM MaxCompositions
    WHERE rn = 1
) sub
WHERE rank_desc <= 10 OR rank_asc <= 10
ORDER BY "Composition Value" DESC NULLS LAST, "Interest Name";