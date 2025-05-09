WITH extensions AS (   -- list all extensions we care about
    SELECT '.py'  AS ext UNION ALL
    SELECT '.c'   UNION ALL
    SELECT '.ipynb' UNION ALL
    SELECT '.java' UNION ALL
    SELECT '.js'
),
files_with_depth AS (  -- keep only files deeper than 10 dirs that match our extensions
    SELECT
        CASE
            WHEN REGEXP_LIKE("path", '\\.py$')    THEN '.py'
            WHEN REGEXP_LIKE("path", '\\.c$')     THEN '.c'
            WHEN REGEXP_LIKE("path", '\\.ipynb$') THEN '.ipynb'
            WHEN REGEXP_LIKE("path", '\\.java$')  THEN '.java'
            WHEN REGEXP_LIKE("path", '\\.js$')    THEN '.js'
        END AS ext
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE REGEXP_COUNT("path", '/') > 10
      AND (
            REGEXP_LIKE("path", '\\.py$')
         OR REGEXP_LIKE("path", '\\.c$')
         OR REGEXP_LIKE("path", '\\.ipynb$')
         OR REGEXP_LIKE("path", '\\.java$')
         OR REGEXP_LIKE("path", '\\.js$')
      )
),
counts AS (            -- aggregate counts per extension
    SELECT ext, COUNT(*) AS file_count
    FROM files_with_depth
    GROUP BY ext
),
final AS (             -- ensure every extension appears, defaulting to 0
    SELECT e.ext AS extension,
           COALESCE(c.file_count, 0) AS file_count
    FROM extensions e
    LEFT JOIN counts c ON e.ext = c.ext
)
SELECT extension, file_count
FROM final
ORDER BY file_count DESC NULLS LAST, extension
LIMIT 1;