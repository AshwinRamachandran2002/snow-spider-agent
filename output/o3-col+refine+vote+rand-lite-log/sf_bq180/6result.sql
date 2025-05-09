WITH python_imports AS (
    SELECT LOWER(REGEXP_SUBSTR(line, 'import\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'e', 1)) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) f,
         LATERAL (SELECT f.value::STRING AS line)
    WHERE sc."sample_path" ILIKE '%.py'
),
python_froms AS (
    SELECT LOWER(REGEXP_SUBSTR(line, 'from\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'e', 1)) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) f,
         LATERAL (SELECT f.value::STRING AS line)
    WHERE sc."sample_path" ILIKE '%.py'
),
r_libs AS (
    SELECT LOWER(REGEXP_SUBSTR(line, 'library\\([\'"]?([A-Za-z0-9_\\.]+)[\'"]?\\)', 1, 1, 'e', 1)) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) f,
         LATERAL (SELECT f.value::STRING AS line)
    WHERE sc."sample_path" ILIKE '%.r'
),
all_modules AS (
    SELECT module FROM python_imports
    UNION ALL
    SELECT module FROM python_froms
    UNION ALL
    SELECT module FROM r_libs
)
SELECT module,
       COUNT(*) AS frequency
FROM all_modules
WHERE module IS NOT NULL
GROUP BY module
ORDER BY frequency DESC NULLS LAST
LIMIT 5;