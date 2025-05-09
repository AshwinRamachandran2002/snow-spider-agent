WITH python_free AS (
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) NOT LIKE '%python%'
),

readme_files AS (
    SELECT f."id"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
    JOIN python_free pf
      ON pf."repo_name" = f."repo_name"
    WHERE LOWER(f."path") LIKE '%readme.md%'
),

counts AS (
    SELECT
        COUNT(*)                                                     AS total_readme_files,
        SUM(CASE WHEN LOWER(c."content") LIKE '%copyright (c)%' 
                 THEN 1 ELSE 0 END)                                  AS matching_files
    FROM readme_files r
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON c."id" = r."id"
)

SELECT
    CASE 
        WHEN total_readme_files = 0 THEN 0
        ELSE matching_files::FLOAT / total_readme_files
    END AS proportion
FROM counts;