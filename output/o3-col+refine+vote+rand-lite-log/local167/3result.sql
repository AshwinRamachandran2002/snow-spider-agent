WITH female_dec31_legislators AS (
    SELECT DISTINCT l.id_bioguide
    FROM legislators            AS l
    JOIN legislators_terms      AS lt
      ON lt.id_bioguide = l.id_bioguide
    WHERE l.gender = 'F'
      AND DATE(lt.term_end) >= DATE(substr(lt.term_start, 1, 4) || '-12-31')
),
first_state_per_legislator AS (
    SELECT  f.id_bioguide,
            ( SELECT lt2.state
              FROM   legislators_terms AS lt2
              WHERE  lt2.id_bioguide = f.id_bioguide
              ORDER  BY lt2.term_start
              LIMIT 1 ) AS first_state
    FROM female_dec31_legislators AS f
)
SELECT  first_state       AS state_abbreviation,
        COUNT(*)          AS female_legislator_count
FROM    first_state_per_legislator
GROUP BY first_state
ORDER BY female_legislator_count DESC,
         state_abbreviation
LIMIT 1;