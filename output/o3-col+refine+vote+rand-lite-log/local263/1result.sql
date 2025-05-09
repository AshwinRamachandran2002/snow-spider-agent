WITH ranked AS (
    SELECT ms."name",
           ms."version",
           MAX(CASE WHEN ms."model" NOT LIKE '%Stack%' THEN ms."test_score" END) AS max_non_stack,
           MAX(CASE WHEN ms."model"  LIKE '%Stack%'    THEN ms."test_score" END) AS stack_score
    FROM   "model_score" ms
    GROUP  BY ms."name", ms."version"
),
status AS (
    SELECT r."name",
           r."version",
           CASE
             WHEN r.stack_score IS NULL           THEN 'no_stack_row'
             WHEN r.stack_score >  r.max_non_stack THEN 'strong'
             WHEN r.stack_score =  r.max_non_stack THEN 'soft'
             ELSE 'other'
           END AS status
    FROM   ranked r
),
stats AS (
    SELECT s.status,
           m."L1_model",
           COUNT(*) AS occurrences
    FROM   status s
    JOIN   "model" m
      ON   s."name"    = m."name"
     AND   s."version" = m."version"
    WHERE  s.status IN ('strong','soft')
    GROUP  BY s.status, m."L1_model"
),
max_stats AS (
    SELECT status,
           MAX(occurrences) AS max_occurrences
    FROM   stats
    GROUP  BY status
)
SELECT st.status,
       st."L1_model",
       st.occurrences
FROM   stats     st
JOIN   max_stats ms
  ON   st.status        = ms.status
 AND   st.occurrences   = ms.max_occurrences
ORDER  BY st.status;