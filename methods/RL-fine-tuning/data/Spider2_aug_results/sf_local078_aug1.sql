-- Task: For each interest category, retrieve the time (MM-YYYY), interest name, and its highest composition value.
WITH MaxComposition AS (
    SELECT im."interest_name", m."interest_id", m."composition", m."month_year",
           RANK() OVER (PARTITION BY m."interest_id" ORDER BY m."composition" DESC) AS comp_rank
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_MAP" AS im
    JOIN "BANK_SALES_TRADING"."BANK_SALES_TRADING"."INTEREST_METRICS" AS m
    ON im."id" = m."interest_id"
)
SELECT 
    "month_year" AS "Time",
    "interest_name" AS "Interest Name",
    ROUND("composition", 4) AS "Highest Composition Value"
FROM MaxComposition
WHERE comp_rank = 1
ORDER BY "Interest Name";