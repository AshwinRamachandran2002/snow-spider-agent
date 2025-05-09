SELECT ms1."model"
FROM STACKING.STACKING.MODEL_SCORE ms1
JOIN STACKING.STACKING.MODEL_SCORE ms2
   ON ms1."name" = ms2."name" AND ms1."version" = ms2."version" AND ms1."step" = ms2."step"
WHERE ms1."model" != 'Stack' AND ms2."model" = 'Stack'
GROUP BY ms1."model"
HAVING 
   SUM(CASE WHEN ms1."test_score" < ms2."test_score" THEN 1 ELSE 0 END) > 
   COUNT(*) / 2;