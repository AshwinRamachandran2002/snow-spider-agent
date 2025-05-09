SELECT COUNT(*) AS "PULL_REQUEST_CREATION_EVENTS"
FROM (
    /* Pull‑request “opened” events that happened on 2023‑01‑18 (UTC) */
    SELECT
        e."id",
        e."repo":"name"::STRING AS REPO_NAME
    FROM GITHUB_REPOS_DATE.YEAR."_2023" AS e
    WHERE e."type" = 'PullRequestEvent'
      /* keep only 2023‑01‑18 */
      AND DATE(
              TO_TIMESTAMP_NTZ(
                  CASE
                      WHEN e."created_at" > 100000000000 THEN e."created_at" / 1000
                      ELSE e."created_at"
                  END
          )) = '2023-01-18'
      /* keep only creation (opened) actions */
      AND PARSE_JSON(e."payload"):"action"::STRING = 'opened'
) pr
JOIN GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES AS l
      ON l."repo_name" = pr.REPO_NAME
/* repository must list JavaScript among its languages */
WHERE UPPER(l."language"::STRING) LIKE '%JAVASCRIPT%';