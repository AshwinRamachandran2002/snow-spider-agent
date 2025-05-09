WITH first_terms AS (
    SELECT
        "id_bioguide",
        MIN("term_start") AS "first_term_start"
    FROM "legislators_terms"
    GROUP BY "id_bioguide"
),
laps AS (
    SELECT
        l."id_bioguide",
        CAST(strftime('%Y', d."date") AS INTEGER)
          - CAST(strftime('%Y', ft."first_term_start") AS INTEGER) AS "years_elapsed"
    FROM "legislation_date_dim"  AS d
    JOIN "legislators_terms"     AS t  ON d."date" BETWEEN t."term_start" AND t."term_end"
    JOIN "legislators"           AS l  ON l."id_bioguide" = t."id_bioguide"
    JOIN first_terms             AS ft ON ft."id_bioguide" = l."id_bioguide"
    WHERE l."gender" = 'M'
      AND t."state"  = 'LA'
      AND strftime('%m-%d', d."date") = '12-31'
)
SELECT
    "years_elapsed",
    COUNT(DISTINCT "id_bioguide") AS "num_legislators"
FROM laps
WHERE "years_elapsed" > 30
  AND "years_elapsed" < 50
GROUP BY "years_elapsed"
ORDER BY "years_elapsed";