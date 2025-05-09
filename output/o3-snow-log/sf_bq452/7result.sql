WITH calls AS (
    /* 1.  Flatten the per–sample calls for every variant on chromosome 12
          and join to the sample meta-data so we know each sample’s
          super-population                                             */
    SELECT
        v."start",
        v."end",
        s."Super_Population"                    AS super_pop,

        /*  Allele counts per diploid sample (assume 0 = ref, >0 = alt) */
        IFF( c.value:"genotype"[0]::INT > 0 , 1 , 0 )
      + IFF( c.value:"genotype"[1]::INT > 0 , 1 , 0 )                  AS alt_cnt,

        2 -
        ( IFF( c.value:"genotype"[0]::INT > 0 , 1 , 0 )
        + IFF( c.value:"genotype"[1]::INT > 0 , 1 , 0 ) )              AS ref_cnt
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v,
         LATERAL FLATTEN( INPUT => v."call" )           c
         JOIN "_1000_GENOMES"."_1000_GENOMES"."SAMPLE_INFO"  s
           ON c.value:"call_set_name"::STRING = s."Sample"
    WHERE v."reference_name" = '12'
      AND c.value:"genotype"[0] IS NOT NULL       -- keep only calls with genotypes
),

/* 2.  Aggregate allele counts per variant for cases (EAS) vs controls (others) */
agg AS (
    SELECT
        "start",
        "end",
        SUM( CASE WHEN super_pop = 'EAS' THEN alt_cnt ELSE 0 END ) AS a,   -- alt in cases
        SUM( CASE WHEN super_pop <> 'EAS' THEN alt_cnt ELSE 0 END ) AS b,  -- alt in controls
        SUM( CASE WHEN super_pop = 'EAS' THEN ref_cnt ELSE 0 END ) AS c,   -- ref in cases
        SUM( CASE WHEN super_pop <> 'EAS' THEN ref_cnt ELSE 0 END ) AS d   -- ref in controls
    FROM calls
    GROUP BY "start","end"
),

/* 3.  Derive totals, expected counts and filter on the Cochran rule (>=5) */
calc AS (
    SELECT
        "start",
        "end",
        a, b, c, d,
        (a+c)                         AS n_cases,
        (b+d)                         AS n_ctrls,
        (a+b)                         AS alt_tot,
        (c+d)                         AS ref_tot,
        (a+b+c+d)                     AS grand_tot,

        /* expected counts */
        (a+c) * (a+b) / (a+b+c+d)     AS exp_alt_cases,
        (b+d) * (a+b) / (a+b+c+d)     AS exp_alt_ctrls,
        (a+c) * (c+d) / (a+b+c+d)     AS exp_ref_cases,
        (b+d) * (c+d) / (a+b+c+d)     AS exp_ref_ctrls
    FROM agg
    WHERE (a+b+c+d) > 0   -- safeguard against divide-by-zero
      AND ( (a+c) * (a+b) / (a+b+c+d)     ) >= 5   -- every expected cell ≥ 5
      AND ( (b+d) * (a+b) / (a+b+c+d)     ) >= 5
      AND ( (a+c) * (c+d) / (a+b+c+d)     ) >= 5
      AND ( (b+d) * (c+d) / (a+b+c+d)     ) >= 5
),

/* 4.  Chi-squared with Yates’s correction */
chi AS (
    SELECT
        "start",
        "end",
        ROUND(
              /* alt / cases */
              POW( ABS(a - exp_alt_cases)  - 0.5 , 2 ) / exp_alt_cases
            + /* alt / ctrls */
              POW( ABS(b - exp_alt_ctrls)  - 0.5 , 2 ) / exp_alt_ctrls
            + /* ref / cases */
              POW( ABS(c - exp_ref_cases)  - 0.5 , 2 ) / exp_ref_cases
            + /* ref / ctrls */
              POW( ABS(d - exp_ref_ctrls)  - 0.5 , 2 ) / exp_ref_ctrls
            , 4)                                                   AS chi_squared
    FROM calc
)

/* 5.  Return variants with χ² ≥ 29.71679, ordered by score */
SELECT
    "start",
    "end",
    chi_squared
FROM chi
WHERE chi_squared >= 29.71679
ORDER BY chi_squared DESC NULLS LAST;