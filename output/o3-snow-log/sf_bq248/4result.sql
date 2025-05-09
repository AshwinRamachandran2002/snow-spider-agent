WITH python_repos AS (
    /* Repositories that list at least one language whose name contains “python” */
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(CAST(f.key AS STRING)) LIKE '%python%'
),
repos_without_python AS (
    /* All repositories appearing in LANGUAGES that do NOT use Python */
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
    LEFT JOIN python_repos p
      ON l."repo_name" = p."repo_name"
    WHERE p."repo_name" IS NULL
),
selected_files AS (
    /* Files that belong to those repositories (restricted to SAMPLE_CONTENTS) */
    SELECT c.*
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
    JOIN repos_without_python r
      ON c."sample_repo_name" = r."repo_name"
)
SELECT
    ROUND(
        COUNT_IF(
            LOWER("sample_path") LIKE '%readme.md%' 
            AND LOWER("content")   LIKE '%copyright (c)%'
        ) :: FLOAT
        /
        NULLIF(COUNT(*), 0)
    , 4
    ) AS "proportion"
FROM selected_files;