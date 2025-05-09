SELECT COUNT(*) AS "num_util_pats_2010_with_one_fw_cit_10yr"
FROM (
    SELECT  p."publication_number",
            COUNT(DISTINCT c.value:"application_number"::STRING) AS "fw_cit_cnt_10yr"
    FROM    PATENTS.PATENTS."PUBLICATIONS"  p,
            LATERAL FLATTEN (INPUT => p."citation") c
    WHERE   p."grant_date"        BETWEEN 20100101 AND 20101231        -- granted in 2010
      AND   p."application_kind"  IN ('A','U')                         -- utility patents
      AND   c.value:"application_number"::STRING IS NOT NULL           -- citing appl. present
      AND   c.value:"application_number"::STRING <> p."application_number"  -- exclude self-cites
      AND   c.value:"filing_date"::NUMBER BETWEEN p."filing_date" 
                                            AND (p."filing_date" + 100000)  -- within 10 yr window
    GROUP BY p."publication_number"
    HAVING COUNT(DISTINCT c.value:"application_number"::STRING) = 1    -- exactly one forward cite
) q;