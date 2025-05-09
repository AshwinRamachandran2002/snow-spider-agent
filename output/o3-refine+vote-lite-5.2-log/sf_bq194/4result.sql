WITH files AS (
    SELECT "sample_path",
           "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.py'
       OR LOWER("sample_path") LIKE '%.ipynb'
       OR LOWER("sample_path") LIKE '%.r'
       OR LOWER("sample_path") LIKE '%.rmd'
),
lines AS (
    SELECT "sample_path",
           TRIM(f.value::STRING) AS line
    FROM files,
         LATERAL FLATTEN(input => SPLIT("content", '\n')) f
),
python_imports AS (        -- import X / from X import Y
    SELECT REGEXP_SUBSTR(line,
                         '\\bimport\\s+([A-Za-z0-9_]+)',
                         1, 1, 'ie', 1)  AS module
    FROM lines
    WHERE REGEXP_LIKE(line, '\\bimport\\s+[A-Za-z0-9_]+', 'i')

    UNION ALL

    SELECT REGEXP_SUBSTR(line,
                         '\\bfrom\\s+([A-Za-z0-9_]+)',
                         1, 1, 'ie', 1)  AS module
    FROM lines
    WHERE REGEXP_LIKE(line, '\\bfrom\\s+[A-Za-z0-9_]+', 'i')
),
r_imports AS (             -- library(...) / require(...)
    SELECT REGEXP_SUBSTR(line,
                         'library\\s*\\([^A-Za-z0-9_]*([A-Za-z0-9_.]+)',
                         1, 1, 'ie', 1)  AS module
    FROM lines
    WHERE REGEXP_LIKE(line, 'library\\s*\\(', 'i')

    UNION ALL

    SELECT REGEXP_SUBSTR(line,
                         'require\\s*\\([^A-Za-z0-9_]*([A-Za-z0-9_.]+)',
                         1, 1, 'ie', 1)  AS module
    FROM lines
    WHERE REGEXP_LIKE(line, 'require\\s*\\(', 'i')
),
all_imports AS (
    SELECT module FROM python_imports
    UNION ALL
    SELECT module FROM r_imports
),
module_counts AS (
    SELECT LOWER(module)                       AS module,
           COUNT(*)                            AS cnt
    FROM all_imports
    WHERE module IS NOT NULL
    GROUP BY LOWER(module)
),
ordered_counts AS (
    SELECT module,
           cnt,
           ROW_NUMBER() OVER (ORDER BY cnt DESC, module) AS rn
    FROM module_counts
)
SELECT module
FROM ordered_counts
WHERE rn = 2;