WITH first_terms AS (
    SELECT l."id_bioguide",
           MIN(CAST(substr(t."term_start", 1, 4) AS INTEGER)) AS first_year
    FROM "legislators"       AS l
    JOIN "legislators_terms" AS t
          ON l."id_bioguide" = t."id_bioguide"
    WHERE l."gender" = 'M'
      AND t."state"  = 'LA'
    GROUP BY l."id_bioguide"
),
dec31_dates AS (
    SELECT "date"
    FROM   "legislation_date_dim"
    WHERE  "month_name"   = 'December'
      AND  "day_of_month" = 31
),
eligible_dates AS (
    SELECT ft."id_bioguide",
           d."date",
           CAST(substr(d."date",1,4) AS INTEGER) - ft.first_year AS years_elapsed
    FROM   dec31_dates AS d
    JOIN   first_terms AS ft
      ON (CAST(substr(d."date",1,4) AS INTEGER) - ft.first_year) > 30
     AND (CAST(substr(d."date",1,4) AS INTEGER) - ft.first_year) < 50
),
active_legislators AS (
    SELECT e.years_elapsed,
           e."id_bioguide"
    FROM   eligible_dates  AS e
    JOIN   "legislators_terms" AS t
          ON t."id_bioguide" = e."id_bioguide"
         AND t."term_start" <= e."date"
         AND t."term_end"   >= e."date"
)
SELECT   years_elapsed,
         COUNT(DISTINCT id_bioguide) AS num_legislators
FROM     active_legislators
GROUP BY years_elapsed
ORDER BY years_elapsed;