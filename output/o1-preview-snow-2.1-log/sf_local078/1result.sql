WITH MaxComposition AS (
    SELECT im."interest_name", m."interest_id", m."composition", m."month_year",
           RANK() OVER (PARTITION BY m."interest_id" ORDER BY m."composition" DESC) AS comp_rank
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" AS im
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS" AS m
    ON im."id" = m."interest_id"
),
MaxCompPerInterest AS (
    SELECT "interest_id", "interest_name", "composition", "month_year"
    FROM MaxComposition
    WHERE comp_rank = 1
),
Combined AS (
    SELECT "interest_id", "interest_name", "composition", "month_year",
           ROW_NUMBER() OVER (ORDER BY "composition" DESC NULLS LAST, "interest_id") AS rn_desc,
           ROW_NUMBER() OVER (ORDER BY "composition" ASC NULLS LAST, "interest_id") AS rn_asc
    FROM MaxCompPerInterest
),
TopBottom10 AS (
    SELECT "interest_id", "interest_name", "composition", "month_year"
    FROM Combined
    WHERE rn_desc <= 10
    UNION ALL
    SELECT "interest_id", "interest_name", "composition", "month_year"
    FROM Combined
    WHERE rn_asc <= 10
)
SELECT "month_year" AS "Time", 
       "interest_name" AS "Interest Name", 
       ROUND("composition", 4) AS "Composition Value"
FROM TopBottom10
ORDER BY "Composition Value" DESC NULLS LAST, "Interest Name";