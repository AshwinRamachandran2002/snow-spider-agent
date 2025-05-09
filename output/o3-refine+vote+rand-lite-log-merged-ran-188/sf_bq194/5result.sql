WITH
/* ---------- Python (*.py) imports ---------- */
py AS (
    SELECT LOWER(
             COALESCE(
               REGEXP_SUBSTR(l.value::STRING, '\\bfrom\\s+([A-Za-z0-9_.]+)', 1, 1, 'i', 1),
               REGEXP_SUBSTR(l.value::STRING, '\\bimport\\s+([A-Za-z0-9_.]+)', 1, 1, 'i', 1)
             )
           ) AS lib
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"  f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
          ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE LOWER(f."path") LIKE '%.py'
      AND (l.value::STRING ILIKE 'import %' OR l.value::STRING ILIKE 'from %')
),
/* ---------- R (*.r / *.rmd) library()/require() calls ---------- */
r AS (
    SELECT LOWER(
             REGEXP_SUBSTR(
               l.value::STRING,
               '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_.]+)',
               1, 1, 'i', 2
             )
           ) AS lib
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"  f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
          ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE (LOWER(f."path") LIKE '%.r' OR LOWER(f."path") LIKE '%.rmd')
      AND (l.value::STRING ILIKE '%library(%' OR l.value::STRING ILIKE '%require(%')
),
/* ---------- IPython notebooks (*.ipynb) – treat as Python ---------- */
ipynb AS (
    SELECT LOWER(
             COALESCE(
               REGEXP_SUBSTR(l.value::STRING, '\\bfrom\\s+([A-Za-z0-9_.]+)', 1, 1, 'i', 1),
               REGEXP_SUBSTR(l.value::STRING, '\\bimport\\s+([A-Za-z0-9_.]+)', 1, 1, 'i', 1)
             )
           ) AS lib
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"  f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
          ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE LOWER(f."path") LIKE '%.ipynb'
      AND (l.value::STRING ILIKE 'import %' OR l.value::STRING ILIKE 'from %')
),
/* ---------- Combine all languages ---------- */
all_libs AS (
    SELECT lib FROM py    WHERE lib IS NOT NULL
    UNION ALL
    SELECT lib FROM r     WHERE lib IS NOT NULL
    UNION ALL
    SELECT lib FROM ipynb WHERE lib IS NOT NULL
)
/* ---------- Rank by frequency and pick the 2nd ---------- */
SELECT lib AS "second_most_frequent_library_or_module"
FROM (
    SELECT
        lib,
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
    FROM all_libs
    GROUP BY lib
) ranked
WHERE rn = 2;