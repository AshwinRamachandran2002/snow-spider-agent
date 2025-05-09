/* Get the latest week in the table, then find the most recent week that is
   52 ± 1 weeks earlier (guarantees the week exists), pick the latest refresh
   for that week and return the #1‑ranked rising term. */
WITH latest_week AS (
    SELECT MAX("week") AS "latest_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS
), target_week AS (
    /* Any week between 52 and 53 weeks earlier; use the most recent one */
    SELECT MAX(tr."week") AS "target_week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN latest_week lw ON 1=1
    WHERE tr."week" <  lw."latest_week"
      AND tr."week" >= DATEADD(week, -53, lw."latest_week")
), latest_refresh_for_target AS (
    /* Latest refresh for that target week */
    SELECT MAX("refresh_date") AS "latest_refresh_date"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN target_week tw
      ON tr."week" = tw."target_week"
), ranked_terms AS (
    SELECT tr."term",
           tr."rank",
           tr."week"
    FROM GOOGLE_TRENDS.GOOGLE_TRENDS.TOP_RISING_TERMS tr
    JOIN target_week tw
      ON tr."week" = tw."target_week"
    JOIN latest_refresh_for_target lr
      ON tr."refresh_date" = lr."latest_refresh_date"
)
SELECT "term",
       "rank",
       "week"
FROM ranked_terms
ORDER BY "rank" ASC NULLS LAST, "term" ASC
FETCH FIRST 1 ROWS ONLY;