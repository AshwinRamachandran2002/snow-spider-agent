-- Task: Extract the modules imported in '.py' and '.r' files by parsing 'import', 'from', and 'library(' statements, and list the file IDs, repository names, file paths, programming languages, and the modules imported, showing only the first 100 results.
WITH extracted_modules AS (
    SELECT 
        el."file_id" AS "file_id", 
        el."repo_name", 
        el."path" AS "path_", 
        REPLACE(line.value, '"', '') AS "line_",
        CASE
            WHEN ENDSWITH(el."path", '.py') THEN 'python'
            WHEN ENDSWITH(el."path", '.r') THEN 'r'
            ELSE NULL
        END AS "language",
        CASE
            WHEN ENDSWITH(el."path", '.py') THEN
                ARRAY_CAT(
                    ARRAY_CONSTRUCT(REGEXP_SUBSTR(line.value, '\\bimport\\s+(\\w+)', 1, 1, 'e')),
                    ARRAY_CONSTRUCT(REGEXP_SUBSTR(line.value, '\\bfrom\\s+(\\w+)', 1, 1, 'e'))
                )
            WHEN ENDSWITH(el."path", '.r') THEN
                ARRAY_CONSTRUCT(REGEXP_SUBSTR(line.value, 'library\\s*\\(\\s*([^\\s)]+)\\s*\\)', 1, 1, 'e'))
            ELSE ARRAY_CONSTRUCT()
        END AS "modules"
    FROM (
        SELECT
            ct."id" AS "file_id", 
            fl."repo_name" AS "repo_name", 
            fl."path", 
            SPLIT(REPLACE(ct."content", '\n', ' \n'), '\n') AS "lines"
        FROM 
            GITHUB_REPOS.GITHUB_REPOS."SAMPLE_FILES" AS fl
        JOIN 
            GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" AS ct 
            ON fl."id" = ct."id"
    ) AS el,
    LATERAL FLATTEN(input => el."lines") AS line 
    WHERE
        (
            ENDSWITH("path_", '.py') 
            AND 
            (
                "line_" LIKE 'import %' 
                OR 
                "line_" LIKE 'from %'
            )
        )
        OR
        (
            ENDSWITH("path_", '.r') 
            AND 
            "line_" LIKE 'library%('
        )
)
SELECT 
    "file_id", 
    "repo_name", 
    "path_", 
    "language", 
    "modules"
FROM 
    extracted_modules
LIMIT 100;