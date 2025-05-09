WITH sample_info AS (     -- keep the super-population label for every sample
    SELECT
        "Sample"           AS sample_id ,
        "Super_Population" AS super_pop
    FROM _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
    WHERE "Super_Population" IS NOT NULL
),

/* ---------------------------------------------------------------------------
   Pull every genotype on chr-12, count reference and alternate alleles
   for each sample, and keep the sample's super-population label.
--------------------------------------------------------------------------- */
variant_allele_totals AS (
    SELECT
        v."start" ,
        v."end"   ,
        si.super_pop ,
        SUM( CASE WHEN g.value::INT > 0 THEN 1 ELSE 0 END ) AS alt_allele_cnt ,
        SUM( CASE WHEN g.value::INT = 0 THEN 1 ELSE 0 END ) AS ref_allele_cnt
    FROM _1000_GENOMES._1000_GENOMES.VARIANTS      v
         , LATERAL FLATTEN( INPUT => v."call" )    c
         INNER JOIN sample_info  si
                    ON si.sample_id = c.value:"call_set_name"::STRING
         , LATERAL FLATTEN( INPUT => c.value:"genotype" ) g
    WHERE v."reference_name" = '12'
    GROUP BY v."start" , v."end" , si.super_pop
),

/* ---------------------------------------------------------------------------
   Build the 2×2 contingency table for every variant
--------------------------------------------------------------------------- */
contingency AS (
    SELECT
        "start" ,
        "end"   ,
        /* EAS (cases) */
        SUM( CASE WHEN super_pop = 'EAS' THEN alt_allele_cnt ELSE 0 END )::FLOAT AS a ,
        SUM( CASE WHEN super_pop = 'EAS' THEN ref_allele_cnt ELSE 0 END )::FLOAT AS b ,
        /* non-EAS (controls) */
        SUM( CASE WHEN super_pop <> 'EAS' THEN alt_allele_cnt ELSE 0 END )::FLOAT AS c ,
        SUM( CASE WHEN super_pop <> 'EAS' THEN ref_allele_cnt ELSE 0 END )::FLOAT AS d
    FROM variant_allele_totals
    GROUP BY "start" , "end"
),

/* ---------------------------------------------------------------------------
   Chi-square with Yates continuity correction.
--------------------------------------------------------------------------- */
chi_calc AS (
    SELECT
        "start" ,
        "end"   ,
        a , b , c , d ,
        (a+b+c+d)                                                 AS n ,
        /* expected counts */
        (a+b)*(a+c)/(a+b+c+d)                                     AS e1 ,
        (a+b)*(b+d)/(a+b+c+d)                                     AS e2 ,
        (c+d)*(a+c)/(a+b+c+d)                                     AS e3 ,
        (c+d)*(b+d)/(a+b+c+d)                                     AS e4 ,
        /* Yates-corrected chi-square */
        CASE
            WHEN ( (a+b)*(c+d)*(a+c)*(b+d) ) = 0 THEN NULL
            ELSE ( (a+b+c+d)
                   * POWER( ABS(a*d - b*c) - ( (a+b+c+d)/2.0 ), 2 )
                 )
                 / ( (a+b)*(c+d)*(a+c)*(b+d) )
        END                                                       AS chi_sq
    FROM contingency
)

/* ---------------------------------------------------------------------------
   Return variants that meet the expected-count threshold (≥5 for every cell)
   and have chi-square ≥ 29.71679.
--------------------------------------------------------------------------- */
SELECT
    "start" ,
    "end" ,
    chi_sq AS chi_squared_score
FROM chi_calc
WHERE chi_sq IS NOT NULL
  AND LEAST(e1, e2, e3, e4) >= 5
  AND chi_sq >= 29.71679
ORDER BY chi_sq DESC NULLS LAST;