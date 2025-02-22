-- Task: Among all repositories that do not use any programming language whose name includes the substring "python" (case-insensitive), compute the proportion of files where the file path, when lowercased, ends with 'readme.md', and the file content contains the exact phrase 'Copyright (c)' (case-sensitive).
WITH requests AS (
    SELECT 
        D."id",
        D."content",
        E."repo_name",
        E."path"
    FROM 
        (
            SELECT 
                "id",
                "content"
            FROM 
                GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
            GROUP BY 
                "id", "content"
        ) AS D
    INNER JOIN 
        (
            SELECT 
                C."id",
                C."repo_name",
                C."path"
            FROM 
                (
                    SELECT 
                        "id",
                        "repo_name",
                        "path"
                    FROM 
                        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
                    WHERE 
                        LOWER("path") LIKE '%readme.md'
                    GROUP BY 
                        "path", "id", "repo_name"
                ) AS C
            INNER JOIN 
                (
                    SELECT 
                        "repo_name",
                        language_struct.value:"name"::STRING AS "language_name"
                    FROM 
                        GITHUB_REPOS.GITHUB_REPOS.LANGUAGES,
                        LATERAL FLATTEN(input => "language") AS language_struct
                    WHERE 
                        LOWER(language_struct.value:"name"::STRING) NOT LIKE '%python%'
                    GROUP BY 
                        "language_name", "repo_name"
                ) AS F
            ON 
                C."repo_name" = F."repo_name"
        ) AS E
    ON 
        D."id" = E."id"
)
SELECT 
    (SELECT COUNT(*) FROM requests WHERE "content" LIKE '%Copyright (c)%') / COUNT(*) AS "proportion"
FROM 
    requests;