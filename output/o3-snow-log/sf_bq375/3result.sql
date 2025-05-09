WITH
  FILE_TYPES AS (
    SELECT column1 AS "FILE_TYPE"
    FROM VALUES
      ('Python'),
      ('C'),
      ('Jupyter Notebook'),
      ('Java'),
      ('JavaScript')
  ),
  COUNTS AS (
    SELECT
      CASE
        WHEN regexp_like(lower("path"), '\\.py$')    THEN 'Python'
        WHEN regexp_like(lower("path"), '\\.c$')     THEN 'C'
        WHEN regexp_like(lower("path"), '\\.ipynb$') THEN 'Jupyter Notebook'
        WHEN regexp_like(lower("path"), '\\.java$')  THEN 'Java'
        WHEN regexp_like(lower("path"), '\\.js$')    THEN 'JavaScript'
      END                          AS "FILE_TYPE",
      COUNT(*)                     AS "FILE_COUNT"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE regexp_count("path", '/') > 10
      AND (
        regexp_like(lower("path"), '\\.py$')    OR
        regexp_like(lower("path"), '\\.c$')     OR
        regexp_like(lower("path"), '\\.ipynb$') OR
        regexp_like(lower("path"), '\\.java$')  OR
        regexp_like(lower("path"), '\\.js$')
      )
    GROUP BY "FILE_TYPE"
  )
SELECT
  ft."FILE_TYPE",
  COALESCE(c."FILE_COUNT", 0) AS "FILE_COUNT"
FROM FILE_TYPES ft
LEFT JOIN COUNTS c
  ON ft."FILE_TYPE" = c."FILE_TYPE"
ORDER BY "FILE_COUNT" DESC NULLS LAST, ft."FILE_TYPE"
LIMIT 1;