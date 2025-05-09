WITH files AS (
    SELECT "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  lower("sample_path") LIKE '%.py'
        OR lower("sample_path") LIKE '%.r'
        OR lower("sample_path") LIKE '%.rmd'
        OR lower("sample_path") LIKE '%.ipynb'
),
seq AS (
    SELECT seq4()+1 AS pos
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),
imports AS (
    /* Python:  import <module> */
    SELECT split_part(
             regexp_substr(lower(f."content"),
                           '\\bimport\\s+([a-z0-9_\\.]+)',
                           1, s.pos, 'i', 1),
             '.', 1) AS lib
    FROM files f
    JOIN seq s
      ON regexp_substr(lower(f."content"),
                       '\\bimport\\s+([a-z0-9_\\.]+)',
                       1, s.pos, 'i', 1) IS NOT NULL

    UNION ALL

    /* Python:  from <module> import ... */
    SELECT split_part(
             regexp_substr(lower(f."content"),
                           '\\bfrom\\s+([a-z0-9_\\.]+)\\s+import',
                           1, s.pos, 'i', 1),
             '.', 1) AS lib
    FROM files f
    JOIN seq s
      ON regexp_substr(lower(f."content"),
                       '\\bfrom\\s+([a-z0-9_\\.]+)\\s+import',
                       1, s.pos, 'i', 1) IS NOT NULL

    UNION ALL

    /* R:  library(<pkg>) */
    SELECT split_part(
             regexp_substr(lower(f."content"),
                           '\\blibrary\\s*\\(\\s*([a-z0-9_\\.]+)',
                           1, s.pos, 'i', 1),
             '.', 1) AS lib
    FROM files f
    JOIN seq s
      ON regexp_substr(lower(f."content"),
                       '\\blibrary\\s*\\(\\s*([a-z0-9_\\.]+)',
                       1, s.pos, 'i', 1) IS NOT NULL

    UNION ALL

    /* R:  require(<pkg>) */
    SELECT split_part(
             regexp_substr(lower(f."content"),
                           '\\brequire\\s*\\(\\s*([a-z0-9_\\.]+)',
                           1, s.pos, 'i', 1),
             '.', 1) AS lib
    FROM files f
    JOIN seq s
      ON regexp_substr(lower(f."content"),
                       '\\brequire\\s*\\(\\s*([a-z0-9_\\.]+)',
                       1, s.pos, 'i', 1) IS NOT NULL
),
totals AS (
    SELECT lib, COUNT(*) AS freq
    FROM imports
    WHERE lib IS NOT NULL AND lib <> ''
    GROUP BY lib
)
SELECT lib
FROM (
    SELECT lib,
           ROW_NUMBER() OVER (ORDER BY freq DESC NULLS LAST, lib) AS rn
    FROM totals
)
WHERE rn = 2;