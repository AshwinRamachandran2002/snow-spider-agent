WITH selected_files AS (
    SELECT
        "sample_path",
        "content",
        CASE
            WHEN LOWER("sample_path") LIKE '%.py' THEN 'py'
            WHEN LOWER("sample_path") LIKE '%.r'  THEN 'r'
        END AS "lang"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.py'
       OR LOWER("sample_path") LIKE '%.r'
),
lines AS (
    SELECT
        sf."lang",
        lt.VALUE AS line
    FROM selected_files sf,
         LATERAL SPLIT_TO_TABLE(sf."content", '\n') lt
),
modules_py AS (        -- extract modules from Python import/from lines
    SELECT
        LOWER(
            COALESCE(
                REGEXP_SUBSTR(line, '^\\s*import\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'e', 1),
                REGEXP_SUBSTR(line, '^\\s*from\\s+([A-Za-z0-9_\\.]+)',   1, 1, 'e', 1)
            )
        ) AS module
    FROM lines
    WHERE "lang" = 'py'
      AND (
            REGEXP_LIKE(line, '^\\s*import\\s+[A-Za-z0-9_\\.]+')
         OR REGEXP_LIKE(line, '^\\s*from\\s+[A-Za-z0-9_\\.]+')
      )
      AND module IS NOT NULL
),
modules_r AS (         -- extract modules from R library() calls
    SELECT
        LOWER(
            REGEXP_SUBSTR(line, '\\blibrary\\s*\\(\\s*[\'"]?([A-Za-z0-9_\\.]+)', 1, 1, 'e', 1)
        ) AS module
    FROM lines
    WHERE "lang" = 'r'
      AND REGEXP_LIKE(line, '\\blibrary\\s*\\(')
      AND module IS NOT NULL
),
all_modules AS (
    SELECT module FROM modules_py
    UNION ALL
    SELECT module FROM modules_r
)
SELECT
    module       AS "module_name",
    COUNT(*)     AS "usage_count"
FROM all_modules
WHERE module IS NOT NULL
GROUP BY module
ORDER BY "usage_count" DESC NULLS LAST, "module_name"
FETCH FIRST 5 ROWS;