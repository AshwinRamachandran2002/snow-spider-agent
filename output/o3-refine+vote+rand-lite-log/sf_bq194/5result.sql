WITH relevant AS (
    SELECT "sample_path",
           "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.py'
       OR LOWER("sample_path") LIKE '%.r'
       OR LOWER("sample_path") LIKE '%.rmd'
       OR LOWER("sample_path") LIKE '%.ipynb'
),
lines AS (
    SELECT "sample_path",
           value::string AS line
    FROM relevant,
         LATERAL FLATTEN(INPUT => SPLIT("content", '\n'))
),
python_imports AS (
    SELECT REGEXP_SUBSTR(
               line,
               '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_.]+)',
               1, 1, 'i', 2
           ) AS module
    FROM lines
    WHERE LOWER("sample_path") LIKE '%.py'
      AND REGEXP_SUBSTR(
              line,
              '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_.]+)',
              1, 1, 'i', 2
          ) IS NOT NULL
),
r_imports AS (
    SELECT REGEXP_SUBSTR(
               line,
               '^[[:space:]]*(library|require)[[:space:]]*\\([[:space:]]*[\'"]?([A-Za-z0-9_.]+)',
               1, 1, 'i', 2
           ) AS module
    FROM lines
    WHERE LOWER("sample_path") LIKE '%.r'
       OR LOWER("sample_path") LIKE '%.rmd'
      AND REGEXP_SUBSTR(
              line,
              '^[[:space:]]*(library|require)[[:space:]]*\\([[:space:]]*[\'"]?([A-Za-z0-9_.]+)',
              1, 1, 'i', 2
          ) IS NOT NULL
),
ipynb_imports AS (
    SELECT REGEXP_SUBSTR(
               line,
               '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_.]+)',
               1, 1, 'i', 2
           ) AS module
    FROM lines
    WHERE LOWER("sample_path") LIKE '%.ipynb'
      AND REGEXP_SUBSTR(
              line,
              '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_.]+)',
              1, 1, 'i', 2
          ) IS NOT NULL
),
all_imports AS (
    SELECT module FROM python_imports
    UNION ALL
    SELECT module FROM r_imports
    UNION ALL
    SELECT module FROM ipynb_imports
),
counts AS (
    SELECT module,
           COUNT(*) AS cnt
    FROM all_imports
    GROUP BY module
    ORDER BY cnt DESC NULLS LAST, module
)
SELECT module
FROM counts
ORDER BY cnt DESC NULLS LAST, module
OFFSET 1 FETCH NEXT 1 ROWS ONLY;