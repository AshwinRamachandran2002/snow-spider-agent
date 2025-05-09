WITH first_start AS (
  /* earliest term‑start date for every legislator */
  SELECT id_bioguide,
         MIN(DATE(term_start)) AS first_start
  FROM legislators_terms
  GROUP BY id_bioguide
),
first_terms AS (
  /* take state and gender from the row that is the first term */
  SELECT DISTINCT
         lt.id_bioguide,
         fs.first_start,
         lt.state,
         l.gender
  FROM first_start        fs
  JOIN legislators_terms  lt ON lt.id_bioguide = fs.id_bioguide
                             AND DATE(lt.term_start) = fs.first_start
  JOIN legislators        l  ON l.id_bioguide = fs.id_bioguide
  WHERE l.gender IN ('M','F')                -- keep only Male / Female
),
/* six checkpoints (0,2,4,6,8,10 years after first start) */
intervals(delta) AS (VALUES (0),(2),(4),(6),(8),(10)),
targets AS (
  /* build the 31‑Dec target date for every legislator & interval */
  SELECT
        ft.id_bioguide,
        ft.state,
        ft.gender,
        i.delta,
        DATE((CAST(strftime('%Y', ft.first_start) AS INTEGER) + i.delta) || '-12-31')
        AS target_date
  FROM first_terms ft
  CROSS JOIN intervals i
),
active AS (
  /* keep rows where the legislator is still in office on the target date */
  SELECT DISTINCT
         t.state,
         t.gender,
         t.delta
  FROM targets t
  JOIN legislators_terms lt
       ON lt.id_bioguide = t.id_bioguide
      AND DATE(t.target_date) BETWEEN DATE(lt.term_start)
                                 AND DATE(COALESCE(lt.term_end, '9999-12-31'))
),
gender_state_ok AS (
  /* a gender‑state cohort is valid if it has at least one member at *all* 6 deltas */
  SELECT state,
         gender
  FROM active
  GROUP BY state, gender
  HAVING COUNT(DISTINCT delta) = 6
),
states_both AS (
  /* keep states where BOTH male and female cohorts are valid */
  SELECT state
  FROM gender_state_ok
  GROUP BY state
  HAVING SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) > 0
     AND SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) > 0
)
SELECT state
FROM states_both
ORDER BY state;