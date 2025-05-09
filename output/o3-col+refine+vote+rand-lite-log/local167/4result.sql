WITH dec_female AS (
    SELECT DISTINCT l."id_bioguide"
    FROM "legislators" AS l
    JOIN "legislators_terms" AS t
      ON l."id_bioguide" = t."id_bioguide"
    WHERE l."gender" = 'F'
      AND date(substr(t."term_start", 1, 4) || '-12-31')
          BETWEEN t."term_start" AND t."term_end"
),
first_terms AS (
    SELECT t."id_bioguide",
           t."state"
    FROM "legislators_terms" AS t
    JOIN dec_female AS df
      ON t."id_bioguide" = df."id_bioguide"
    WHERE t."term_start" = (
        SELECT MIN("term_start")
        FROM "legislators_terms"
        WHERE "id_bioguide" = t."id_bioguide"
    )
)
SELECT "state",
       COUNT(*) AS female_legislator_count
FROM first_terms
GROUP BY "state"
ORDER BY female_legislator_count DESC
LIMIT 1;