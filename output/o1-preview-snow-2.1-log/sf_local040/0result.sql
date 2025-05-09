WITH tree_counts AS (
    SELECT t."boroname" AS "Borough",
           COUNT(*) AS "Number_of_Trees"
    FROM MODERN_DATA.MODERN_DATA.TREES t
    GROUP BY t."boroname"
),
income_per_borough AS (
    SELECT t."boroname" AS "Borough",
           ROUND(AVG(i."Estimate_Mean_income"), 4) AS "Average_Mean_Income"
    FROM MODERN_DATA.MODERN_DATA.TREES t
    JOIN MODERN_DATA.MODERN_DATA.INCOME_TREES i
      ON t."zipcode" = i."zipcode"
    WHERE i."Estimate_Median_income" > 0
      AND i."Estimate_Mean_income" > 0
    GROUP BY t."boroname"
)
SELECT tc."Borough",
       tc."Number_of_Trees",
       ipb."Average_Mean_Income"
FROM tree_counts tc
JOIN income_per_borough ipb
  ON tc."Borough" = ipb."Borough"
ORDER BY tc."Number_of_Trees" DESC NULLS LAST
LIMIT 3;