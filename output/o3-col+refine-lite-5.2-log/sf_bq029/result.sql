WITH ca_inv AS (
    /* 1.  Flatten the inventor array and count inventors per Canadian publication */
    SELECT  p."publication_number",
            COUNT(inv.value) AS inventor_cnt,
            TO_NUMBER(SUBSTR(CAST(p."publication_date" AS TEXT),1,4)) AS pub_year
    FROM    PATENTS.PATENTS.PUBLICATIONS p,
            LATERAL FLATTEN(input => p."inventor") inv
    WHERE   p."country_code" = 'CA'
    GROUP BY p."publication_number", p."publication_date"
    HAVING  inventor_cnt > 0                      -- keep only publications that list ≥1 inventor
)
SELECT
    /* 2.  Bucket the publication years into 5‑year intervals */
    CASE
        WHEN pub_year BETWEEN 1960 AND 1964 THEN '1960-1964'
        WHEN pub_year BETWEEN 1965 AND 1969 THEN '1965-1969'
        WHEN pub_year BETWEEN 1970 AND 1974 THEN '1970-1974'
        WHEN pub_year BETWEEN 1975 AND 1979 THEN '1975-1979'
        WHEN pub_year BETWEEN 1980 AND 1984 THEN '1980-1984'
        WHEN pub_year BETWEEN 1985 AND 1989 THEN '1985-1989'
        WHEN pub_year BETWEEN 1990 AND 1994 THEN '1990-1994'
        WHEN pub_year BETWEEN 1995 AND 1999 THEN '1995-1999'
        WHEN pub_year BETWEEN 2000 AND 2004 THEN '2000-2004'
        WHEN pub_year BETWEEN 2005 AND 2009 THEN '2005-2009'
        WHEN pub_year BETWEEN 2010 AND 2014 THEN '2010-2014'
        WHEN pub_year BETWEEN 2015 AND 2019 THEN '2015-2019'
        WHEN pub_year = 2020                    THEN '2020-2020'
    END                                        AS "five_year_period",
    AVG(inventor_cnt)                          AS "avg_inventors",
    COUNT(*)                                   AS "pub_cnt"
FROM   ca_inv
WHERE  pub_year BETWEEN 1960 AND 2020
GROUP  BY "five_year_period"
ORDER  BY "five_year_period";