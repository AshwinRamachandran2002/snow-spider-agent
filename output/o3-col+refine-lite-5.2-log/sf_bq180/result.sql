WITH python_modules AS (
    /* Python: lines starting with “import …” */
    SELECT LOWER(
             REGEXP_SUBSTR(l.value::STRING,
                           '^[[:space:]]*import[[:space:]]+([A-Za-z0-9_\\.]+)',
                           1, 1, 'e', 1)
           ) AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE c."sample_path" ILIKE '%.py'
      AND l.value::STRING ILIKE 'import %'

    UNION ALL

    /* Python: lines starting with “from … import …” */
    SELECT LOWER(
             REGEXP_SUBSTR(l.value::STRING,
                           '^[[:space:]]*from[[:space:]]+([A-Za-z0-9_\\.]+)',
                           1, 1, 'e', 1)
           ) AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE c."sample_path" ILIKE '%.py'
      AND l.value::STRING ILIKE 'from %import%'
),
r_modules AS (
    /* R: lines containing “library(<pkg>)” */
    SELECT LOWER(
             REGEXP_SUBSTR(l.value::STRING,
                           'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                           1, 1, 'e', 1)
           ) AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE (c."sample_path" ILIKE '%.r' OR c."sample_path" ILIKE '%.R')
      AND l.value::STRING ILIKE '%library(%'
),
all_modules AS (
    SELECT module FROM python_modules
    UNION ALL
    SELECT module FROM r_modules
)
SELECT
    module,
    COUNT(*) AS total_freq
FROM all_modules
WHERE module IS NOT NULL
GROUP BY module
ORDER BY total_freq DESC NULLS LAST, module    -- tie‑breaker on name
LIMIT 5;