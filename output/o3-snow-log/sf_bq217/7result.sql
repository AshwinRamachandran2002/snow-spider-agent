WITH pr_events AS (
    /* Pull-request creation events on 2023-01-18 */
    SELECT
        e."repo":name::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2023" AS e
    WHERE e."type" = 'PullRequestEvent'
      AND PARSE_JSON(e."payload"):action::STRING = 'opened'                 -- PR created
      AND DATE(TO_TIMESTAMP(e."created_at" / 1000000)) = '2023-01-18'       -- event date
), js_repos AS (
    /* Repositories that list JavaScript among their detected languages */
    SELECT
        l."repo_name"
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES AS l
    WHERE l."language":JavaScript IS NOT NULL                               -- has JavaScript
)
SELECT COUNT(*) AS "pull_request_creation_events"
FROM pr_events AS p
JOIN js_repos  AS j
  ON p."repo_name" = j."repo_name";