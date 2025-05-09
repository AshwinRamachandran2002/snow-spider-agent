WITH first_term AS (
    SELECT "id_bioguide",
           MIN("term_start") AS "first_term_start"
    FROM "legislators_terms"
    GROUP BY "id_bioguide"
),
dec31 AS (
    SELECT "date"
    FROM "legislation_date_dim"
    WHERE "date" LIKE '%-12-31'
),
active_on_dec31 AS (
    SELECT lt."id_bioguide",
           CAST(substr(d."date",1,4) AS INTEGER) -
           CAST(substr(ft."first_term_start",1,4) AS INTEGER) AS "years_since_first"
    FROM "legislators_terms" lt
    JOIN "legislators"      l  ON l."id_bioguide" = lt."id_bioguide"
    JOIN first_term         ft ON ft."id_bioguide" = lt."id_bioguide"
    JOIN dec31              d  ON lt."term_start" <= d."date"
                               AND lt."term_end"   >= d."date"
    WHERE l."gender" = 'M'
      AND lt."state"  = 'LA'
)
SELECT "years_since_first"  AS "years_elapsed_since_first_term",
       COUNT(DISTINCT "id_bioguide") AS "distinct_legislators_active_on_dec_31"
FROM   active_on_dec31
WHERE  "years_since_first" > 30
  AND  "years_since_first" < 50
GROUP  BY "years_since_first"
ORDER  BY "years_since_first";