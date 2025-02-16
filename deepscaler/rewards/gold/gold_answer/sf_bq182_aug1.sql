-- Task: List all events on January 18, 2023 with their corresponding repository names (up to 100 records).
SELECT
  "type",
  EXTRACT(YEAR FROM TO_TIMESTAMP("created_at" / 1000000)) AS "year",
  EXTRACT(QUARTER FROM TO_TIMESTAMP("created_at" / 1000000)) AS "quarter",
  REGEXP_REPLACE(
    "repo"::variant:"url"::string,
    'https:\\/\\/github\\.com\\/|https:\\/\\/api\\.github\\.com\\/repos\\/',
    ''
  ) AS "name"
FROM GITHUB_REPOS_DATE.DAY."_20230118"
LIMIT 100;