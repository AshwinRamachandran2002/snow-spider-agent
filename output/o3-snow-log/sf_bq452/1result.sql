WITH sample_groups AS (          -- label every sample as CASE (EAS) or CONTROL (non-EAS)
    SELECT
        "Sample"                                                    AS sample_id,
        CASE WHEN "Super_Population" = 'EAS' THEN 'case' ELSE 'control' END AS grp
    FROM _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
    WHERE "Sample" IS NOT NULL
),

variant_allele_counts AS (       -- explode every genotype call, count REF / ALT alleles per group
    SELECT
        v."start",
        v."end",
        sg.grp,
        SUM( IFF( c.value:"genotype"[0]::INT > 0 , 1, 0)      -- ALT allele #1
            + IFF( c.value:"genotype"[1]::INT > 0 , 1, 0) )   AS alt_cnt,
        SUM( IFF( c.value:"genotype"[0]::INT = 0 , 1, 0)      -- REF allele #1
            + IFF( c.value:"genotype"[1]::INT = 0 , 1, 0) )   AS ref_cnt
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS  v,
         LATERAL FLATTEN ( INPUT => v."call" )                c
         JOIN sample_groups                                   sg
           ON sg.sample_id = c.value:"call_set_name"::STRING
    WHERE v."reference_name" = '12'                           -- chromosome 12 only
          -- ignore missing genotypes (coded –1)
          AND c.value:"genotype"[0]::INT <> -1
          AND c.value:"genotype"[1]::INT <> -1
    GROUP BY v."start", v."end", sg.grp
),

counts AS (                      -- assemble 2×2 table:  a b / c d
    SELECT
        "start",
        "end",
        SUM( CASE WHEN grp = 'case'    THEN alt_cnt ELSE 0 END ) AS a,   -- ALT  in cases
        SUM( CASE WHEN grp = 'control' THEN alt_cnt ELSE 0 END ) AS b,   -- ALT  in controls
        SUM( CASE WHEN grp = 'case'    THEN ref_cnt ELSE 0 END ) AS c,   -- REF  in cases
        SUM( CASE WHEN grp = 'control' THEN ref_cnt ELSE 0 END ) AS d    -- REF  in controls
    FROM variant_allele_counts
    GROUP BY "start", "end"
),

stats AS (                       -- expected counts + chi-square (Yates)
    SELECT
        "start",
        "end",
        a, b, c, d,
        (a+b+c+d)::FLOAT                         AS n,
        ((a+b)*(a+c)/(a+b+c+d))::FLOAT           AS exp_alt_case,
        ((a+b)*(b+d)/(a+b+c+d))::FLOAT           AS exp_alt_ctrl,
        ((c+d)*(a+c)/(a+b+c+d))::FLOAT           AS exp_ref_case,
        ((c+d)*(b+d)/(a+b+c+d))::FLOAT           AS exp_ref_ctrl,
        /* Yates corrected chi-square */
        ( (a+b+c+d)
          * POWER( ABS(a*d - b*c) - ( (a+b+c+d)/2.0 ), 2 )
          / ( (a+b)*(c+d)*(a+c)*(b+d) )
        )                                        AS chi_squared
    FROM counts
    WHERE (a+b) > 0 AND (c+d) > 0 AND (a+c) > 0 AND (b+d) > 0   -- avoid zero denominator
          -- ensure every expected cell ≥ 5
          AND LEAST(
                ((a+b)*(a+c)/(a+b+c+d)),
                ((a+b)*(b+d)/(a+b+c+d)),
                ((c+d)*(a+c)/(a+b+c+d)),
                ((c+d)*(b+d)/(a+b+c+d))
              ) >= 5
)

SELECT
    "start",
    "end",
    chi_squared
FROM stats
WHERE chi_squared >= 29.71679
ORDER BY chi_squared DESC NULLS LAST;