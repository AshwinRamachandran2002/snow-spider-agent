SELECT "term" AS rising_search_term
FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
WHERE "refresh_date" = (
        SELECT MAX("refresh_date")
        FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS"
      )
  AND "week" = DATEADD(
        week, -52,
        (SELECT MAX("week")
         FROM "GOOGLE_TRENDS"."GOOGLE_TRENDS"."TOP_RISING_TERMS")
      )
  AND "rank" = 1
ORDER BY "percent_gain" DESC NULLS LAST
LIMIT 1;