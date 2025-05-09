WITH py_files AS (
    SELECT f."id",
           c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES  f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON c."id" = f."id"
    WHERE LOWER(f."path") LIKE '%.py'
),
/* ------------------------------------------------------------------ */
/* Python:  import  <module> ........................................ */
py_imports AS (
    SELECT
        'python'                                                     AS "language",
        REGEXP_SUBSTR(p."content",
                      'import\\s+([A-Za-z0-9_.]+)',          1,
                      g.idx, 'e', 1)                                 AS "module"
    FROM py_files                p,
         LATERAL (SELECT seq4()+1 AS idx
                  FROM TABLE(GENERATOR(ROWCOUNT => 100))) g
    WHERE REGEXP_SUBSTR(p."content",
                        'import\\s+([A-Za-z0-9_.]+)',        1,
                        g.idx, 'e', 1) IS NOT NULL
),
/* Python:  from <module> import .................................... */
py_froms AS (
    SELECT
        'python'                                                     AS "language",
        REGEXP_SUBSTR(p."content",
                      'from\\s+([A-Za-z0-9_.]+)\\s+import',  1,
                      g.idx, 'e', 1)                                 AS "module"
    FROM py_files                p,
         LATERAL (SELECT seq4()+1 AS idx
                  FROM TABLE(GENERATOR(ROWCOUNT => 100))) g
    WHERE REGEXP_SUBSTR(p."content",
                        'from\\s+([A-Za-z0-9_.]+)\\s+import',1,
                        g.idx, 'e', 1) IS NOT NULL
),
/* ------------------------------------------------------------------ */
/* R files .......................................................... */
r_files AS (
    SELECT f."id",
           c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES  f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON c."id" = f."id"
    WHERE LOWER(f."path") LIKE '%.r'
),
/* R:  library(<package>) .......................................... */
r_libs AS (
    SELECT
        'r'                                                          AS "language",
        REGEXP_SUBSTR(r."content",
                      'library\\s*\\(\\s*([A-Za-z0-9_.]+)\\s*\\)', 1,
                      g.idx, 'e', 1)                                 AS "module"
    FROM r_files                r,
         LATERAL (SELECT seq4()+1 AS idx
                  FROM TABLE(GENERATOR(ROWCOUNT => 100))) g
    WHERE REGEXP_SUBSTR(r."content",
                        'library\\s*\\(\\s*([A-Za-z0-9_.]+)\\s*\\)', 1,
                        g.idx, 'e', 1) IS NOT NULL
),
/* ------------------------------------------------------------------ */
all_modules AS (
    SELECT * FROM py_imports
    UNION ALL
    SELECT * FROM py_froms
    UNION ALL
    SELECT * FROM r_libs
)
/* ------------------------------------------------------------------ */
SELECT
    "language",
    "module",
    COUNT(*)        AS "occurrences"
FROM all_modules
GROUP BY "language", "module"
ORDER BY
    "language" ASC,
    "occurrences" DESC NULLS LAST,
    "module" ASC;