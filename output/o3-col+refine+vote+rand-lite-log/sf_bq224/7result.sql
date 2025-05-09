WITH april_pull_requests AS (     -- PullRequestEvents in April 2022
    SELECT
        PARSE_JSON("payload"):"pull_request":"base":"repo" AS repo_obj
    FROM GITHUB_REPOS_DATE.YEAR._2022
    WHERE "type" = 'PullRequestEvent'
      AND "created_at" BETWEEN 1648771200000000   -- 2022-04-01 00:00 UTC
                          AND 1651363200000000   -- 2022-05-01 00:00 UTC
),
repo_scores AS (                  -- forks + issues + watchers per event
    SELECT
        repo_obj:"full_name"::STRING AS repo_name,
        (  COALESCE(repo_obj:"forks_count",0)::NUMBER
         + COALESCE(repo_obj:"open_issues_count",0)::NUMBER
         + COALESCE(repo_obj:"watchers_count",0)::NUMBER ) AS combined_score
    FROM april_pull_requests
),
max_score_per_repo AS (           -- best score per repository
    SELECT
        repo_name,
        MAX(combined_score) AS combined_score
    FROM repo_scores
    GROUP BY repo_name
),
licensed_repos AS (               -- keep repos with approved licenses
    SELECT
        m.repo_name,
        l."license",
        m.combined_score
    FROM max_score_per_repo m
    JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
          ON l."repo_name" = m.repo_name
    WHERE l."license" ILIKE 'apache-%'
       OR l."license" ILIKE 'mit%'
       OR l."license" ILIKE 'gpl-%'
       OR l."license" ILIKE 'bsd%'
       OR l."license" ILIKE 'mpl-%'
)
SELECT
    repo_name,
    "license",
    combined_score
FROM licensed_repos
ORDER BY combined_score DESC NULLS LAST
LIMIT 1;