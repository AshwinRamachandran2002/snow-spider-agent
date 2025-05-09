SELECT ms1."model"
FROM "model_score" AS ms1
JOIN "model_score" AS ms2
  ON ms1."name" = ms2."name"
  AND ms1."version" = ms2."version"
  AND ms1."step" = ms2."step"
  AND ms2."model" = 'Stack'
WHERE ms1."model" != 'Stack'
GROUP BY ms1."model"
HAVING SUM(CASE WHEN ms1."test_score" < ms2."test_score" THEN 1 ELSE 0 END) >
       SUM(CASE WHEN ms1."test_score" > ms2."test_score" THEN 1 ELSE 0 END);