WITH py_files AS (
    SELECT c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    WHERE c."binary" = FALSE
      AND LOWER(f."path") LIKE '%.py'
),
r_files AS (
    SELECT c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    WHERE c."binary" = FALSE
      AND LOWER(f."path") LIKE '%.r'
),
python_imports AS (
    SELECT LOWER(
             REGEXP_SUBSTR(t.value,
                           '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                           1, 1, 'e', 1)
           ) AS module
    FROM py_files,
         LATERAL SPLIT_TO_TABLE(py_files."content", '\n') t
    WHERE REGEXP_SUBSTR(t.value,
                        '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                        1, 1, 'e', 1) IS NOT NULL
),
python_from_imports AS (
    SELECT LOWER(
             REGEXP_SUBSTR(t.value,
                           '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',
                           1, 1, 'e', 1)
           ) AS module
    FROM py_files,
         LATERAL SPLIT_TO_TABLE(py_files."content", '\n') t
    WHERE REGEXP_SUBSTR(t.value,
                        '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',
                        1, 1, 'e', 1) IS NOT NULL
),
r_libraries AS (
    SELECT LOWER(
             REGEXP_SUBSTR(t.value,
                           '\\blibrary\\s*\\(\\s*([A-Za-z0-9\\.]+)',
                           1, 1, 'e', 1)
           ) AS module
    FROM r_files,
         LATERAL SPLIT_TO_TABLE(r_files."content", '\n') t
    WHERE REGEXP_SUBSTR(t.value,
                        '\\blibrary\\s*\\(\\s*([A-Za-z0-9\\.]+)',
                        1, 1, 'e', 1) IS NOT NULL
),
modules_union AS (
    SELECT 'Python' AS language, module FROM python_imports      WHERE module <> ''
    UNION ALL
    SELECT 'Python',           module FROM python_from_imports   WHERE module <> ''
    UNION ALL
    SELECT 'R',                module FROM r_libraries           WHERE module <> ''
)
SELECT language,
       module,
       COUNT(*) AS occurrences
FROM   modules_union
GROUP  BY language, module
ORDER  BY language,
         occurrences DESC NULLS LAST,
         module;