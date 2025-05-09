SELECT ROUND(AVG("career_span_years"), 4) AS "Average_Career_Span_Years"
FROM
(
  SELECT "player_id",
    DATEDIFF(day, TRY_TO_DATE("debut", 'YYYY-MM-DD'), TRY_TO_DATE("final_game", 'YYYY-MM-DD')) AS total_days,
    DATEDIFF(month, TRY_TO_DATE("debut", 'YYYY-MM-DD'), TRY_TO_DATE("final_game", 'YYYY-MM-DD')) AS total_months,
    -- Calculate career span in years according to specified rules
    CASE 
      WHEN total_days >= 365 THEN 
        FLOOR(total_days / 365)
      WHEN total_months >= 1 THEN 
        total_months / 12.0
      ELSE 
        total_days / 365.0
    END AS "career_span_years"
  FROM BASEBALL.BASEBALL.PLAYER
  WHERE TRY_TO_DATE("debut", 'YYYY-MM-DD') IS NOT NULL AND TRY_TO_DATE("final_game", 'YYYY-MM-DD') IS NOT NULL
) t;