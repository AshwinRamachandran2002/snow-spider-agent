SELECT
  ROUND(AVG("Career_Span_Years"), 4) AS "Average_Career_Span_Years"
FROM
(
  SELECT
    CASE
      WHEN DATEDIFF('year', TO_DATE("debut", 'YYYY-MM-DD'), TO_DATE("final_game", 'YYYY-MM-DD')) >= 1
        THEN DATEDIFF('year', TO_DATE("debut", 'YYYY-MM-DD'), TO_DATE("final_game", 'YYYY-MM-DD')) * 1.0
      WHEN DATEDIFF('month', TO_DATE("debut", 'YYYY-MM-DD'), TO_DATE("final_game", 'YYYY-MM-DD')) >= 1
        THEN DATEDIFF('month', TO_DATE("debut", 'YYYY-MM-DD'), TO_DATE("final_game", 'YYYY-MM-DD')) / 12.0
      ELSE DATEDIFF('day', TO_DATE("debut", 'YYYY-MM-DD'), TO_DATE("final_game", 'YYYY-MM-DD')) / 365.0
    END AS "Career_Span_Years"
  FROM
    BASEBALL.BASEBALL.PLAYER
  WHERE
    "debut" IS NOT NULL AND TRIM("debut") != '' AND 
    "final_game" IS NOT NULL AND TRIM("final_game") != '' AND
    TRY_TO_DATE("debut", 'YYYY-MM-DD') IS NOT NULL AND 
    TRY_TO_DATE("final_game", 'YYYY-MM-DD') IS NOT NULL AND
    TO_DATE("final_game", 'YYYY-MM-DD') >= TO_DATE("debut", 'YYYY-MM-DD')
) AS career_spans;