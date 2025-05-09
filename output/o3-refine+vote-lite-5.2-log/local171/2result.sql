WITH RECURSIVE
-- integers 31 … 49  ( >30  and  <50 )
numbers(n) AS (
    SELECT 31
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 49
),
/* male legislators that have ever represented Louisiana */
male_la AS (
    SELECT DISTINCT l."id_bioguide"
    FROM legislators            AS l
    JOIN legislators_terms AS lt ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'M'
      AND lt."state" = 'LA'
),
/* first term start‑date for each of those legislators */
first_terms AS (
    SELECT lt."id_bioguide",
           MIN(lt."term_start") AS first_start
    FROM legislators_terms lt
    JOIN male_la m ON m."id_bioguide" = lt."id_bioguide"
    GROUP BY lt."id_bioguide"
)
/* count how many distinct legislators are in office on 31‑Dec
   of each elapsed‑year (31 … 49) since their first term */
SELECT
    n AS years_elapsed_since_first_term,
    COUNT(DISTINCT ft."id_bioguide") AS legislators_active_on_dec31
FROM numbers
JOIN first_terms ft
WHERE EXISTS (
    SELECT 1
    FROM legislators_terms t
    WHERE t."id_bioguide" = ft."id_bioguide"
      AND DATE(
              printf('%d-12-31',
                     CAST(substr(ft.first_start,1,4) AS INTEGER) + n)
          ) BETWEEN t."term_start" AND t."term_end"
)
GROUP BY n
ORDER BY n;