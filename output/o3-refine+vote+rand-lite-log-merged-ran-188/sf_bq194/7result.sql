WITH python_mods AS (
    SELECT REGEXP_SUBSTR(
             f.value::STRING,
             '^\\s*(from|import)\\s+([A-Za-z0-9_\\.]+)',
             1, 1, 'e', 2
           ) AS "lib"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
           LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
    WHERE  sc."sample_path" ILIKE '%.py'
),
r_mods AS (
    SELECT REGEXP_SUBSTR(
             f.value::STRING,
             '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
             1, 1, 'e', 2
           ) AS "lib"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
           LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
    WHERE  sc."sample_path" ILIKE '%.r'
        OR sc."sample_path" ILIKE '%.R'
        OR sc."sample_path" ILIKE '%.Rmd'
        OR sc."sample_path" ILIKE '%.rmd'
),
nb_mods AS (
    SELECT REGEXP_SUBSTR(
             f.value::STRING,
             '\\bimport\\s+([A-Za-z0-9_\\.]+)',
             1, 1, 'e', 1
           ) AS "lib"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
           LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) f
    WHERE  sc."sample_path" ILIKE '%.ipynb'
),
aggregated AS (
    SELECT "lib",
           COUNT(*) AS "total_occurrences"
    FROM  (
            SELECT * FROM python_mods
            UNION ALL
            SELECT * FROM r_mods
            UNION ALL
            SELECT * FROM nb_mods
          )
    WHERE  "lib" IS NOT NULL
    GROUP BY "lib"
)
SELECT  "lib",
        "total_occurrences"
FROM    aggregated
QUALIFY ROW_NUMBER() OVER (ORDER BY "total_occurrences" DESC) = 2;