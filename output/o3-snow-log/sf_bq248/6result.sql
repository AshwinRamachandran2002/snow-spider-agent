WITH repos_without_python AS (
    -- Repositories whose recorded languages do NOT contain the substring "python"
    SELECT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE NOT LOWER(CAST("language" AS STRING)) LIKE '%python%'
),

repo_files AS (
    -- All files (from the contents sample) that belong to those repositories
    SELECT sc.*
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
    JOIN repos_without_python r
      ON sc."sample_repo_name" = r."repo_name"
),

numerator AS (
    -- Files whose path includes "readme.md" and whose contents contain "copyright (c)"
    SELECT COUNT(*) AS num_files
    FROM repo_files
    WHERE LOWER("sample_path")  LIKE '%readme.md%'
      AND LOWER("content")      LIKE '%copyright (c)%'
),

denominator AS (
    -- Total number of files in the selected repositories
    SELECT COUNT(*) AS total_files
    FROM repo_files
)

-- Final proportion (rounded to four decimal places)
SELECT 
    CASE 
        WHEN d.total_files = 0 THEN NULL
        ELSE ROUND(n.num_files / d.total_files, 4)
    END AS proportion_of_matching_files
FROM numerator   n
CROSS JOIN denominator d;