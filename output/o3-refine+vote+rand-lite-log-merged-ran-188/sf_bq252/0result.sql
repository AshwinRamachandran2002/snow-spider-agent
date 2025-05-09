WITH "swift_files" AS (
    SELECT 
        F."id",
        C."copies"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES   F
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS C
          ON F."id" = C."id"
    WHERE LOWER(F."path") LIKE '%.swift'
      AND (C."binary" = FALSE OR C."binary" IS NULL)
),
"most_copied_swift" AS (
    SELECT 
        "id"
    FROM "swift_files"
    QUALIFY "copies" = MAX("copies") OVER ()
)
SELECT DISTINCT
       F."repo_name"
FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES F
JOIN   "most_copied_swift" M
       ON F."id" = M."id"
ORDER BY F."repo_name" NULLS LAST
LIMIT 1;