/* second-most frequently imported/loaded Python or R library/module */
WITH
-- Python source-like files (.py, .ipynb)
py_files AS (
    SELECT *
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'
        OR LOWER("sample_path") LIKE '%.ipynb'
),
-- R source-like files (.r, .R, .rmd, .Rmd)
r_files AS (
    SELECT *
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.r'
        OR LOWER("sample_path") LIKE '%.rmd'
),
-- extract every imported/loaded library name
imports AS (
    /* Python  ➜  “import X” */
    SELECT REGEXP_SUBSTR(l.value::STRING,
                         '\\bimport\\s+([A-Za-z0-9_\\.]+)',1,1,'e',1) AS "LIBRARY"
    FROM py_files c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') l
    WHERE l.value ILIKE 'import %'
      AND REGEXP_SUBSTR(l.value::STRING,
                        '\\bimport\\s+([A-Za-z0-9_\\.]+)',1,1,'e',1) IS NOT NULL

    UNION ALL

    /* Python  ➜  “from X import …” */
    SELECT REGEXP_SUBSTR(l.value::STRING,
                         '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',1,1,'e',1)
    FROM py_files c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') l
    WHERE l.value ILIKE 'from % import %'
      AND REGEXP_SUBSTR(l.value::STRING,
                        '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',1,1,'e',1) IS NOT NULL

    UNION ALL

    /* R  ➜  “library(pkg)”  or  “require(pkg)” */
    SELECT REGEXP_SUBSTR(l.value::STRING,
                         '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',1,1,'e',2)
    FROM r_files c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') l
    WHERE (l.value ILIKE 'library(%' OR l.value ILIKE 'require(%')
      AND REGEXP_SUBSTR(l.value::STRING,
                        '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',1,1,'e',2) IS NOT NULL
)
-- rank libraries by frequency and pick the 2nd-most common
SELECT  "LIBRARY",
        "TOTAL_IMPORTS"
FROM (
    SELECT  "LIBRARY",
            COUNT(*) AS "TOTAL_IMPORTS",
            ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS "RN"
    FROM imports
    GROUP BY "LIBRARY"
)
WHERE "RN" = 2
ORDER BY "TOTAL_IMPORTS" DESC NULLS LAST;