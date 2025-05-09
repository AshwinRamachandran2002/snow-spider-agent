/* Most active Python repository in April 2022 */
WITH issue_counts AS (          -- Issue-related activity in Apr-2022
    SELECT
        "repo":"name"::string            AS repo_name,
        COUNT(*)                         AS issue_count
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" IN ('IssuesEvent','IssueCommentEvent')
      AND  TO_TIMESTAMP_NTZ("created_at"/1000000)
           BETWEEN '2022-04-01' AND '2022-05-01'
    GROUP BY repo_name
),
fork_counts AS (               -- Fork activity in Apr-2022
    SELECT
        "repo":"name"::string            AS repo_name,
        COUNT(*)                         AS fork_count
    FROM   GITHUB_REPOS_DATE.YEAR._2022
    WHERE  "type" = 'ForkEvent'
      AND  TO_TIMESTAMP_NTZ("created_at"/1000000)
           BETWEEN '2022-04-01' AND '2022-05-01'
    GROUP BY repo_name
),
python_repos AS (              -- Repos with *.py on master branch
    SELECT DISTINCT
        "repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
    WHERE  "ref"  = 'refs/heads/master'
      AND  LOWER("path") LIKE '%.py'
)
SELECT
    sr."repo_name",
    COALESCE(fc.fork_count ,0)                AS fork_count,
    COALESCE(ic.issue_count,0)                AS issue_count,
    COALESCE(sr."watch_count",0)              AS watch_count,
    COALESCE(fc.fork_count ,0)
  + COALESCE(ic.issue_count,0)
  + COALESCE(sr."watch_count",0)              AS activity_score
FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS  sr
JOIN   python_repos                                 pr  ON sr."repo_name" = pr."repo_name"
JOIN   GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES      lic ON sr."repo_name" = lic."repo_name"
LEFT   JOIN issue_counts                            ic  ON sr."repo_name" = ic.repo_name
LEFT   JOIN fork_counts                             fc  ON sr."repo_name" = fc.repo_name
WHERE  LOWER(lic."license") IN ('artistic-2.0','isc','mit','apache-2.0')
ORDER  BY activity_score DESC NULLS LAST
LIMIT  1;