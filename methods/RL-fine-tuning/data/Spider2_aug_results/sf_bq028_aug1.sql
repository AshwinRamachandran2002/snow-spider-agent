-- Task: Find the latest release version for each NPM package, and display up to 100 packages.
SELECT
    "Name",
    "Version"
FROM (
    SELECT
        "Name",
        "Version",
        ROW_NUMBER() OVER (
            PARTITION BY "Name"
            ORDER BY 
                TO_NUMBER(PARSE_JSON("VersionInfo"):"Ordinal") DESC
        ) AS RowNumber
    FROM
        DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE
        "System" = 'NPM'
        AND TO_BOOLEAN(PARSE_JSON("VersionInfo"):"IsRelease") = TRUE
) AS HR
WHERE HR.RowNumber = 1
LIMIT 100;