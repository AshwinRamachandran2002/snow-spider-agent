WITH primary_language AS (
    /* Determine the primary (largest-bytes) language for each repo */
    SELECT
        l."repo_name",
        f.value:"name"::STRING  AS language_name,
        ROW_NUMBER() OVER (PARTITION BY l."repo_name"
                           ORDER BY f.value:"bytes"::NUMBER DESC) AS rn
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
),
js_primary_repos AS (
    /* Keep repos whose primary language is JavaScript */
    SELECT "repo_name"
    FROM primary_language
    WHERE rn = 1
      AND language_name = 'JavaScript'
),
commit_counts AS (
    /* Count commits for those repositories */
    SELECT c."repo_name",
           COUNT(*) AS commit_count
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
    JOIN   js_primary_repos j
           ON c."repo_name" = j."repo_name"
    GROUP BY c."repo_name"
)
SELECT "repo_name",
       commit_count
FROM   commit_counts
ORDER BY commit_count DESC NULLS LAST
LIMIT 2;