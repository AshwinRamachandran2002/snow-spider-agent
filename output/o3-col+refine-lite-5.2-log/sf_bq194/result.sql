WITH py AS (   /* -------- Python source files (*.py) -------- */
     SELECT REGEXP_SUBSTR(line.value::STRING,
                          '^(from|import)\\s+([A-Za-z0-9_\\.]+)',
                          1, 1, 'i', 2)        AS "name"
     FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      f
     JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   c
            ON f."id" = c."id",
            LATERAL FLATTEN(input => SPLIT(c."content", '\n')) line
     WHERE  f."path" ILIKE '%.py'
       AND ( line.value::STRING ILIKE 'import %'
          OR line.value::STRING ILIKE 'from % import %' )
),  /* -------- R files (*.r, *.R, *.rmd, *.Rmd) -------- */
r  AS (
     SELECT REGEXP_SUBSTR(line.value::STRING,
                          '(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                          1, 1, 'i', 2)        AS "name"
     FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   c,
            LATERAL FLATTEN(input => SPLIT(c."content", '\n')) line
     WHERE  REGEXP_SUBSTR(line.value::STRING,
                          '(library|require)\\s*\\(',
                          1, 1, 'i') IS NOT NULL
),  /* -------- Jupyter notebooks (*.ipynb) -------- */
ip AS (
     SELECT REGEXP_SUBSTR(line.value::STRING,
                          '(from|import)\\s+([A-Za-z0-9_\\.]+)',
                          1, 1, 'i', 2)        AS "name"
     FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      f
     JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   c
            ON f."id" = c."id",
            LATERAL FLATTEN(input => SPLIT(c."content", '\n')) line
     WHERE  f."path" ILIKE '%.ipynb'
       AND ( line.value::STRING ILIKE '%import %'
          OR line.value::STRING ILIKE '%from % import %' )
),  /* -------- Combine, count and rank -------- */
all_libs AS (
     SELECT "name"
     FROM   py
     UNION ALL
     SELECT "name"
     FROM   r
     UNION ALL
     SELECT "name"
     FROM   ip
     WHERE  "name" IS NOT NULL
), freq AS (
     SELECT "name",
            COUNT(*) AS total_mentions
     FROM   all_libs
     WHERE  "name" IS NOT NULL
     GROUP  BY "name"
)
SELECT      "name"          AS library_or_module,
            total_mentions
FROM        freq
QUALIFY     ROW_NUMBER() OVER (ORDER BY total_mentions DESC NULLS LAST, "name") = 2;