WITH total_trees AS (
    SELECT "boroname" AS "Borough", COUNT(*) AS "Number_of_Trees"
    FROM "MODERN_DATA"."MODERN_DATA"."TREES"
    GROUP BY "boroname"
),
borough_zipcodes AS (
    SELECT DISTINCT "boroname" AS "Borough", "zipcode"
    FROM "MODERN_DATA"."MODERN_DATA"."TREES"
    WHERE "zipcode" IS NOT NULL
),
income_per_borough AS (
    SELECT b."Borough",
           ROUND(AVG(i."Estimate_Mean_income"), 4) AS "Average_Mean_Income"
    FROM borough_zipcodes b
    JOIN "MODERN_DATA"."MODERN_DATA"."INCOME_TREES" i
      ON b."zipcode" = i."zipcode"
    WHERE i."Estimate_Mean_income" > 0 AND i."Estimate_Median_income" > 0
    GROUP BY b."Borough"
)
SELECT t."Borough", t."Number_of_Trees", i."Average_Mean_Income"
FROM total_trees t
LEFT JOIN income_per_borough i ON t."Borough" = i."Borough"
ORDER BY t."Number_of_Trees" DESC NULLS LAST
LIMIT 3;