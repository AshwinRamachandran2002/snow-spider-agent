SELECT
    "refresh_date",
    MAX(CASE WHEN "rank" = 1 THEN "term" END) AS "rank_1_term",
    MAX(CASE WHEN "rank" = 2 THEN "term" END) AS "rank_2_term",
    MAX(CASE WHEN "rank" = 3 THEN "term" END) AS "rank_3_term"
FROM GOOGLE_TRENDS.GOOGLE_TRENDS."TOP_TERMS"
WHERE "week" BETWEEN '2024-09-01' AND '2024-09-14'
  AND "rank" IN (1, 2, 3)
  AND DATE_PART('DAYOFWEEKISO', "refresh_date") BETWEEN 1 AND 5 -- Monday‑Friday
GROUP BY "refresh_date"
ORDER BY "refresh_date" DESC NULLS LAST;