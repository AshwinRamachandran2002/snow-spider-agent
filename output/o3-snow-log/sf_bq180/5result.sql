WITH lines AS (
    SELECT
        CASE
            WHEN LOWER(f."path") LIKE '%.py' THEN 'python'
            WHEN LOWER(f."path") LIKE '%.r'  THEN 'r'
        END                           AS lang,
        t.VALUE                       AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON c."id" = f."id"
         ,LATERAL SPLIT_TO_TABLE(c."content", '\n') t          -- one row per line
    WHERE LOWER(f."path") LIKE '%.py'
       OR LOWER(f."path") LIKE '%.r'
),
modules AS (
    SELECT
        CASE
            WHEN lang = 'python' THEN
                 COALESCE(
                     REGEXP_SUBSTR(line, '^\\s*import\\s+([A-Za-z0-9_]+)', 1, 1, 'e'),
                     REGEXP_SUBSTR(line, '^\\s*from\\s+([A-Za-z0-9_]+)',   1, 1, 'e')
                 )
            WHEN lang = 'r' THEN
                 REGEXP_SUBSTR(line, '^\\s*library\\s*\\(\\s*([A-Za-z0-9\\.]+)', 1, 1, 'e')
        END AS module
    FROM lines
)
SELECT
    module,
    COUNT(*) AS frequency
FROM modules
WHERE module IS NOT NULL
  AND module <> ''
GROUP BY module
ORDER BY frequency DESC NULLS LAST
LIMIT 5;