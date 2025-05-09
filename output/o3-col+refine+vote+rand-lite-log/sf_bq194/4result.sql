WITH py AS (                                                         -- extract Python-style “import …”
    SELECT LOWER(
             REGEXP_SUBSTR(
               sc."content",
               'import\\s+([A-Za-z0-9_]+)',
               1,
               gen.seq + 1,          -- make occurrence index 1-based
               'e',
               1                     -- capture group #1 = module name
             )
           ) AS name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL (SELECT seq4() AS seq
                  FROM TABLE(GENERATOR(ROWCOUNT => 20))) gen
    WHERE sc."sample_path" ILIKE '%.py'      -- Python scripts
       OR sc."sample_path" ILIKE '%.ipynb'   -- Jupyter notebooks
),
r AS (                                                          -- extract R library()/require(…) calls
    SELECT LOWER(
             REGEXP_SUBSTR(
               sc."content",
               '(library|require)\\s*\\(\\s*([A-Za-z0-9._]+)',
               1,
               gen.seq + 1,
               'e',
               2                     -- capture group #2 = package name
             )
           ) AS name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL (SELECT seq4() AS seq
                  FROM TABLE(GENERATOR(ROWCOUNT => 20))) gen
    WHERE sc."sample_path" ILIKE '%.r'
       OR sc."sample_path" ILIKE '%.R'
       OR sc."sample_path" ILIKE '%.Rmd'
       OR sc."sample_path" ILIKE '%.rmd'
),
all_libs AS (                             -- put everything together
    SELECT name FROM py
    UNION ALL
    SELECT name FROM r
),
usage_counts AS (                         -- count occurrences
    SELECT name,
           COUNT(*) AS usage_count
    FROM all_libs
    WHERE name IS NOT NULL
    GROUP BY name
),
ranked AS (                               -- rank by frequency
    SELECT name,
           usage_count,
           DENSE_RANK() OVER (ORDER BY usage_count DESC) AS rnk
    FROM usage_counts
)
SELECT name   AS "second_most_used_library_or_module",
       usage_count
FROM ranked
WHERE rnk = 2                             -- second most frequent
ORDER BY name;