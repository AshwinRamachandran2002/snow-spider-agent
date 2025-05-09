WITH highest_release AS (
    -- highest (max ordinal) released version per NPM package
    SELECT  pv."Name",
            pv."Version"
    FROM    "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    JOIN    (
              SELECT  "Name",
                      MAX("VersionInfo":"Ordinal"::NUMBER) AS "MaxOrdinal"
              FROM    "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
              WHERE   "System" = 'NPM'
                AND   "VersionInfo":"IsRelease"::BOOLEAN = TRUE
              GROUP BY "Name"
            ) hi
          ON  pv."Name" = hi."Name"
         AND pv."VersionInfo":"Ordinal"::NUMBER = hi."MaxOrdinal"
    WHERE   pv."System" = 'NPM'
      AND   pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
deps_of_highest AS (
    -- dependencies of those highest-release versions
    SELECT  d."Dependency":"Name"::STRING    AS "DepName",
            d."Dependency":"Version"::STRING AS "DepVersion"
    FROM    "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    JOIN    highest_release h
           ON d."System"  = 'NPM'
          AND d."Name"    = h."Name"
          AND d."Version" = h."Version"
)
-- most frequent (dependency package, dependency version) pair
SELECT  "DepName",
        "DepVersion",
        COUNT(*) AS "Appearances"
FROM    deps_of_highest
GROUP BY "DepName", "DepVersion"
ORDER BY "Appearances" DESC NULLS LAST
LIMIT 1;