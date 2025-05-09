WITH april_events AS (
    SELECT
        "repo":"name"::TEXT          AS repo_name,
        COUNT(*)                    AS total_events      -- each row is a Fork, Issue, or Watch
    FROM GITHUB_REPOS_DATE.YEAR."_2022"
    WHERE "type" IN ('ForkEvent','IssuesEvent','WatchEvent')
          -- convert micro‑seconds epoch → date, keep only April 2022
          AND TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) 
              BETWEEN '2022-04-01' AND '2022-04-30'
    GROUP BY repo_name
)
SELECT
    ae.repo_name,
    ae.total_events                AS combined_forks_issues_watches
FROM april_events      ae
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES  l
  ON ae.repo_name = l."repo_name"             -- keep repos whose license is recorded (approved)
WHERE l."license" IS NOT NULL
ORDER BY combined_forks_issues_watches DESC NULLS LAST
LIMIT 1;