WITH avg_birth_rate AS (
    SELECT cs."country_code", cs."short_name" AS "Country", cs."region" AS "Region",
           ROUND(AVG(id."value"), 4) AS "Average Crude Birth Rate"
    FROM "WORLD_BANK"."WORLD_BANK_WDI"."COUNTRY_SUMMARY" cs
    JOIN "WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA" id
      ON cs."country_code" = id."country_code"
    WHERE cs."income_group" = 'High income'
      AND id."indicator_name" = 'Birth rate, crude (per 1,000 people)'
      AND id."year" BETWEEN 1980 AND 1989
    GROUP BY cs."country_code", cs."short_name", cs."region"
)
SELECT a."Country", a."Region", a."Average Crude Birth Rate"
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY "Region" ORDER BY "Average Crude Birth Rate" DESC NULLS LAST) AS rn
    FROM avg_birth_rate
) a
WHERE rn = 1;