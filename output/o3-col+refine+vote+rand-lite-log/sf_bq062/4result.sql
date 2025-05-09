/* Most frequently used license for each package ecosystem (“System”) */
SELECT
    sub."System",
    sub."License"         AS "MostCommonLicense",
    sub."LicenseCount"    AS "PackageCountUsingLicense"
FROM (
    SELECT
        pv."System",
        l.value::STRING        AS "License",
        COUNT(*)               AS "LicenseCount",
        ROW_NUMBER() OVER (
            PARTITION BY pv."System"
            ORDER BY COUNT(*) DESC
        )                      AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS  pv,
         LATERAL FLATTEN(input => pv."Licenses") l
    GROUP BY
        pv."System",
        l.value::STRING
) sub
WHERE sub.rn = 1
ORDER BY sub."System";