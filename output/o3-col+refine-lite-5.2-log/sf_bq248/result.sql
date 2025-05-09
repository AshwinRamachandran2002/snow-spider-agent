WITH non_python_repos AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE CAST("language" AS STRING) NOT ILIKE '%python%'
),
filtered_files AS (
    SELECT 
        c."sample_path",
        c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
    JOIN non_python_repos                     AS r
          ON c."sample_repo_name" = r."repo_name"
)
SELECT
    /* numerator */
    SUM(
        CASE 
            WHEN LOWER("sample_path") LIKE '%readme.md%' 
             AND LOWER("content")     LIKE '%copyright (c)%' 
            THEN 1 ELSE 0 
        END
    )                                           AS "num_readme_with_copyright",
    /* denominator */
    COUNT(*)                                    AS "total_files_non_python",
    /* proportion */
    SUM(
        CASE 
            WHEN LOWER("sample_path") LIKE '%readme.md%' 
             AND LOWER("content")     LIKE '%copyright (c)%' 
            THEN 1 ELSE 0 
        END
    )::FLOAT / NULLIF(COUNT(*),0)              AS "proportion"
FROM filtered_files;