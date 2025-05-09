SELECT COUNT(*) AS "pull_request_creations_js_repos"
FROM (
        /* pull-request creations on 2023-01-18 */
        SELECT
               PARSE_JSON("repo"):"name"::string AS repo_name
        FROM   GITHUB_REPOS_DATE.YEAR._2023
        WHERE  "type" = 'PullRequestEvent'
          AND  PARSE_JSON("payload"):"action"::string = 'opened'
          AND  TO_DATE(
                  CONVERT_TIMEZONE(
                      'UTC',
                      TO_TIMESTAMP_LTZ("created_at" / 1000000)
                  )
               ) = '2023-01-18'
     ) pr
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES lang
  ON pr.repo_name = lang."repo_name"
WHERE lang."language"::string ILIKE '%JavaScript%';