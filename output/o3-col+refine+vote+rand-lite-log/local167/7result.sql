WITH first_state AS (
    SELECT
        lt."id_bioguide",
        (SELECT "state"
         FROM "legislators_terms"
         WHERE "id_bioguide" = lt."id_bioguide"
         ORDER BY "term_start"
         LIMIT 1) AS "first_state"
    FROM "legislators_terms" lt
    GROUP BY lt."id_bioguide"
),
dec31_female_ids AS (
    SELECT DISTINCT lt."id_bioguide"
    FROM "legislators_terms" lt
    JOIN "legislators" l
      ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'F'
      AND DATE(lt."term_start") <= DATE(substr(lt."term_end",1,4) || '-12-31')
)
SELECT
    fs."first_state"      AS state_abbrev,
    COUNT(*)              AS female_legislator_count
FROM first_state fs
JOIN dec31_female_ids d
  ON fs."id_bioguide" = d."id_bioguide"
GROUP BY fs."first_state"
ORDER BY female_legislator_count DESC
LIMIT 1;