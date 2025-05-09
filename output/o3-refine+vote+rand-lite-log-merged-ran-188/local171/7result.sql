WITH first_terms AS (
    /* 1. First (earliest) term start for every male Louisiana legislator */
    SELECT lt."id_bioguide",
           MIN(lt."term_start") AS first_term_start
    FROM   "legislators_terms" AS lt
    JOIN   "legislators"       AS l
           ON l."id_bioguide" = lt."id_bioguide"
    WHERE  lt."state" = 'LA'
      AND  l."gender" = 'M'
    GROUP BY lt."id_bioguide"
),
dec31 AS (
    /* 2. All December-31 calendar dates */
    SELECT "date"
    FROM   "legislation_date_dim"
    WHERE  "month_name"   = 'December'
      AND  "day_of_month" = 31
),
active AS (
    /* 3. Legislator–date combinations where the legislator was in office
          on that December-31 date, plus years elapsed since the first term */
    SELECT l."id_bioguide",
           d."date",
           CAST(strftime('%Y', d."date") AS INTEGER) -
           CAST(substr(ft.first_term_start, 1, 4) AS INTEGER) AS years_elapsed
    FROM   first_terms          AS ft
    JOIN   "legislators"        AS l
           ON l."id_bioguide" = ft."id_bioguide"
    JOIN   "legislators_terms"  AS lt
           ON lt."id_bioguide" = l."id_bioguide"
    JOIN   dec31                AS d
           ON d."date" BETWEEN lt."term_start" AND lt."term_end"
)
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS active_legislators
FROM   active
WHERE  years_elapsed > 30          -- strictly more than 30 years
  AND  years_elapsed < 50          -- strictly less than 50 years
GROUP BY years_elapsed
ORDER BY years_elapsed;