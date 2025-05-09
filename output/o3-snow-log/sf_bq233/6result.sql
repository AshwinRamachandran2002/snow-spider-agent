/* Count Python “import … / from … import …” modules
   and R “library(…)” packages, then list them together */
WITH python_raw AS (          -- Extract imported Python modules
    SELECT
        REGEXP_SUBSTR(
            line.value::STRING,
            '^\\s*(from\\s+|import\\s+)([A-Za-z0-9_.]+)',
            1, 1, 'e', 2                                   -- capture group 2
        ) AS package
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
          ON c."id" = f."id",
          LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) line
    WHERE f."path" ILIKE '%.py'
      AND REGEXP_SUBSTR(
              line.value::STRING,
              '^\\s*(from\\s+|import\\s+)([A-Za-z0-9_.]+)',
              1, 1, 'e', 2
          ) IS NOT NULL
),
python_counts AS (
    SELECT
        'Python'        AS language,
        package,
        COUNT(*)        AS occurrences
    FROM python_raw
    GROUP BY package
),
r_raw AS (                  -- Extract library() calls in R files
    SELECT
        REGEXP_SUBSTR(
            line.value::STRING,
            'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
            1, 1, 'e', 1                               -- capture group 1
        ) AS package
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
          LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) line
    WHERE sc."sample_path" ILIKE '%.r'
      AND REGEXP_SUBSTR(
              line.value::STRING,
              'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
              1, 1, 'e', 1
          ) IS NOT NULL
),
r_counts AS (
    SELECT
        'R'             AS language,
        package,
        COUNT(*)        AS occurrences
    FROM r_raw
    GROUP BY package
)
SELECT language,
       package,
       occurrences
FROM (
      SELECT * FROM python_counts
      UNION ALL
      SELECT * FROM r_counts
)
ORDER BY language,
         occurrences DESC NULLS LAST;