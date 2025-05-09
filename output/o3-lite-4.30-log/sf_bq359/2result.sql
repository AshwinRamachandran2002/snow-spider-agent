WITH language_rank AS (
    SELECT
        l."repo_name",
        f.value:"name"::STRING AS language_name,
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::NUMBER DESC
        ) AS rn
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" l,
         LATERAL FLATTEN(input => l."language") f
), primary_js_repos AS (
    SELECT "repo_name"
    FROM language_rank
    WHERE rn = 1
      AND language_name = 'JavaScript'
)
SELECT
    sc."repo_name"  AS repository_name,
    COUNT(*)        AS commit_count
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" sc
JOIN primary_js_repos p
  ON sc."repo_name" = p."repo_name"
GROUP BY sc."repo_name"
ORDER BY commit_count DESC NULLS LAST, repository_name
LIMIT 2;