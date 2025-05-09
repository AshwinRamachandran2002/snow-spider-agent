WITH commit_counts AS (                       -- total commits per repository
    SELECT
        "repo_name",
        COUNT(*) AS commit_count
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
),
lang_ranks AS (                               -- rank languages by bytes per repo
    SELECT
        l."repo_name",
        f.value:"name"::STRING  AS language_name,
        f.value:"bytes"::NUMBER AS bytes,
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::NUMBER DESC
        ) AS rn                                 -- rn = 1 ⇒ primary language
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
),
primary_js_repos AS (                         -- repos whose primary language is JavaScript
    SELECT "repo_name"
    FROM lang_ranks
    WHERE rn = 1
      AND language_name = 'JavaScript'
)
SELECT
    cc."repo_name",
    cc.commit_count
FROM commit_counts cc
JOIN primary_js_repos pj
  ON cc."repo_name" = pj."repo_name"
ORDER BY cc.commit_count DESC NULLS LAST
LIMIT 2;