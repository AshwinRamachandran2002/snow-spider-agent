WITH py_contents AS (
    SELECT
        SPLIT(c."content", '\n') AS lines
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
    INNER JOIN
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f ON c."id" = f."id"
    WHERE
        f."path" LIKE '%.py' OR f."path" LIKE '%.ipynb'
),
py_lines AS (
    SELECT value AS line
    FROM py_contents,
    LATERAL FLATTEN(input => lines)
),
py_modules AS (
    SELECT
        COALESCE(
            REGEXP_SUBSTR(line, '^\\s*from\\s+([\\w\\.]+)', 1, 1, 'i', 1),
            REGEXP_SUBSTR(line, '^\\s*import\\s+([\\w\\.]+)', 1, 1, 'i', 1)
        ) AS module_name
    FROM py_lines
    WHERE line ILIKE '%import %'
),
extracted_py_modules AS (
    SELECT LOWER(module_name) AS module_name
    FROM py_modules
    WHERE module_name IS NOT NULL
),
r_contents AS (
    SELECT
        SPLIT(c."content", '\n') AS lines
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
    INNER JOIN
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f ON c."id" = f."id"
    WHERE
        f."path" LIKE '%.R'
),
r_lines AS (
    SELECT value AS line
    FROM r_contents,
    LATERAL FLATTEN(input => lines)
),
r_modules AS (
    SELECT
        REGEXP_SUBSTR(line, '^\\s*(?:library|require)\\(\\s*([\\w\\.]+)', 1, 1, 'i', 1) AS module_name
    FROM r_lines
    WHERE line ILIKE '%library(%' OR line ILIKE '%require(%'
),
extracted_r_modules AS (
    SELECT LOWER(module_name) AS module_name
    FROM r_modules
    WHERE module_name IS NOT NULL
),
all_modules AS (
    SELECT module_name FROM extracted_py_modules
    UNION ALL
    SELECT module_name FROM extracted_r_modules
),
module_counts AS (
    SELECT module_name, COUNT(*) AS Frequency
    FROM all_modules
    GROUP BY module_name
),
ordered_modules AS (
    SELECT module_name, Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC NULLS LAST, module_name) AS rn
    FROM module_counts
)
SELECT 'Module,Frequency'
UNION ALL
SELECT module_name || ',' || Frequency::VARCHAR
FROM ordered_modules
WHERE rn = 2;