WITH best_non_stack AS (
    SELECT name,
           version,
           MAX(test_score) AS best_non_stack
    FROM model_score
    WHERE model NOT LIKE '%Stack%'
      AND model NOT LIKE '%STK%'
      AND model NOT LIKE '%STACK%'
    GROUP BY name, version
),
stack_score AS (
    SELECT name,
           version,
           MAX(test_score) AS stack_score
    FROM model_score
    WHERE model LIKE '%Stack%'
       OR model LIKE '%STK%'
       OR model LIKE '%STACK%'
    GROUP BY name, version
),
status AS (
    SELECT bns.name,
           bns.version,
           CASE
               WHEN ss.stack_score IS NULL               THEN 'no_stack'
               WHEN ss.stack_score >  bns.best_non_stack THEN 'strong'
               WHEN ss.stack_score =  bns.best_non_stack THEN 'soft'
               ELSE 'weaker'
           END AS status
    FROM best_non_stack AS bns
    LEFT JOIN stack_score AS ss
           ON bns.name = ss.name
          AND bns.version = ss.version
),
counted AS (
    SELECT s.status,
           m.L1_model,
           COUNT(*) AS nb_occurrences
    FROM status AS s
    JOIN model  AS m
      ON s.name = m.name
     AND s.version = m.version
    WHERE s.status IN ('strong', 'soft')
    GROUP BY s.status, m.L1_model
),
max_counts AS (
    SELECT status,
           MAX(nb_occurrences) AS max_cnt
    FROM counted
    GROUP BY status
)
SELECT c.status,
       c.L1_model,
       c.nb_occurrences
FROM counted AS c
JOIN max_counts AS mc
  ON c.status = mc.status
 AND c.nb_occurrences = mc.max_cnt
ORDER BY c.status;