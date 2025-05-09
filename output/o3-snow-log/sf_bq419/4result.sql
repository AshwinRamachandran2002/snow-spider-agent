/*  Top-5 states with the greatest number of historic-severe-storm events
    between 1980-1995, counting only those states that ranked inside the
    top-1 000 for their respective year                                         */

WITH "yearly_top" AS (

    /* ============================== 1980 ============================== */
    SELECT '1980' AS "yr", "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1980"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1981 ============================== */
    SELECT '1981', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1981"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1982 ============================== */
    SELECT '1982', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1982"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1983 ============================== */
    SELECT '1983', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1983"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1984 ============================== */
    SELECT '1984', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1984"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1985 ============================== */
    SELECT '1985', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1985"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1986 ============================== */
    SELECT '1986', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1986"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1987 ============================== */
    SELECT '1987', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1987"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1988 ============================== */
    SELECT '1988', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1988"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1989 ============================== */
    SELECT '1989', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1989"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1990 ============================== */
    SELECT '1990', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1990"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1991 ============================== */
    SELECT '1991', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1991"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1992 ============================== */
    SELECT '1992', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1992"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1993 ============================== */
    SELECT '1993', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1993"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1994 ============================== */
    SELECT '1994', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1994"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000

    UNION ALL
    /* ============================== 1995 ============================== */
    SELECT '1995', "state", "cnt"
    FROM (
        SELECT  "state",
                COUNT(*) AS "cnt",
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
        FROM    "NOAA_DATA"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_1995"
        GROUP BY "state"
    )
    WHERE  "rn" <= 1000
)

SELECT  "state",
        SUM("cnt") AS "total_events_1980_1995"
FROM    "yearly_top"
GROUP BY "state"
ORDER BY "total_events_1980_1995" DESC
LIMIT 5;