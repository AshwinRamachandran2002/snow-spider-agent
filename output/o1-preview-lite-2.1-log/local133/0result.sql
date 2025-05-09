WITH style_scores AS (
  SELECT
    mp."StyleID",
    SUM(
      CASE mp."PreferenceSeq"
        WHEN 1 THEN 3
        WHEN 2 THEN 2
        WHEN 3 THEN 1
        ELSE 0
      END
    ) AS "TotalWeightedScore"
  FROM "Musical_Preferences" mp
  GROUP BY mp."StyleID"
),
average_score AS (
  SELECT AVG("TotalWeightedScore") AS "AverageWeightedScore" FROM style_scores
)
SELECT
  ms."StyleName",
  ss."TotalWeightedScore",
  ROUND(ABS(ss."TotalWeightedScore" - average_score."AverageWeightedScore"), 4) AS "AbsoluteDifferenceFromAverage"
FROM style_scores ss
JOIN "Musical_Styles" ms ON ss."StyleID" = ms."StyleID"
JOIN average_score
ORDER BY ms."StyleName"