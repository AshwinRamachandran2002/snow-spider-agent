SELECT DISTINCT "sample_repo_name"
FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
WHERE  LOWER("sample_path") LIKE '%.swift'          -- only Swift source files
  AND  "binary" = FALSE                             -- exclude binaries
  AND  "copies" = (                                 -- match the highest copy count
        SELECT MAX("copies")
        FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
        WHERE  LOWER("sample_path") LIKE '%.swift'
          AND  "binary" = FALSE
       );