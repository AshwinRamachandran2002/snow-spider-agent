WITH sample_sp AS (                           -- map sample → super-population
    SELECT  "Sample"            AS sample_id ,
            "Super_Population"  AS super_pop
    FROM    _1000_GENOMES._1000_GENOMES.SAMPLE_INFO
    WHERE   "Super_Population" IS NOT NULL
),
genotypes AS (                               -- raw genotype info for chr-12, biallelic sites
    SELECT  v."start"                               AS pos_start ,
            v."end"                                 AS pos_end  ,
            f.value:"call_set_name"::STRING         AS sample_id ,
            f.value:"genotype"[0]::INT              AS allele1  ,
            f.value:"genotype"[1]::INT              AS allele2
    FROM    _1000_GENOMES._1000_GENOMES."VARIANTS" v
          , LATERAL FLATTEN( input => v."call") f
    WHERE   v."reference_name" = '12'
      AND   ARRAY_SIZE( v."alternate_bases") = 1          -- keep only biallelic variants
),
allele_counts AS (                           -- ref/alt allele counts per (variant , sample)
    SELECT  g.pos_start ,
            g.pos_end  ,
            s.super_pop ,
            (IFF(g.allele1 = 0 ,1,0) + IFF(g.allele2 = 0 ,1,0)) AS ref_cnt ,
            (IFF(g.allele1 > 0 ,1,0) + IFF(g.allele2 > 0 ,1,0)) AS alt_cnt
    FROM    genotypes g
    JOIN    sample_sp s  ON s.sample_id = g.sample_id
    WHERE   g.allele1 IS NOT NULL AND g.allele2 IS NOT NULL      -- ignore missing
),
variant_totals AS (                          -- 2×2 table counts
    SELECT  pos_start ,
            pos_end ,
            SUM( IFF(super_pop = 'EAS', ref_cnt , 0)) AS a_ref_case ,
            SUM( IFF(super_pop = 'EAS', alt_cnt , 0)) AS b_alt_case ,
            SUM( IFF(super_pop <> 'EAS', ref_cnt , 0)) AS c_ref_ctrl ,
            SUM( IFF(super_pop <> 'EAS', alt_cnt , 0)) AS d_alt_ctrl
    FROM    allele_counts
    GROUP BY pos_start , pos_end
),
totals AS (                                  -- row / column totals
    SELECT  pos_start ,
            pos_end ,
            a_ref_case , b_alt_case , c_ref_ctrl , d_alt_ctrl ,
            (a_ref_case + b_alt_case)              AS case_tot ,
            (c_ref_ctrl + d_alt_ctrl)              AS ctrl_tot ,
            (a_ref_case + c_ref_ctrl)              AS ref_tot  ,
            (b_alt_case + d_alt_ctrl)              AS alt_tot
    FROM    variant_totals
),
filtered AS (                                -- keep variants with expected ≥ 5
    SELECT  *,
            (case_tot * ref_tot)  / (case_tot + ctrl_tot) AS exp_a ,
            (case_tot * alt_tot) / (case_tot + ctrl_tot) AS exp_b ,
            (ctrl_tot * ref_tot) / (case_tot + ctrl_tot) AS exp_c ,
            (ctrl_tot * alt_tot) / (case_tot + ctrl_tot) AS exp_d
    FROM    totals
    WHERE   ref_tot  > 0
      AND   alt_tot  > 0
      AND   case_tot > 0
      AND   ctrl_tot > 0
      AND   (case_tot * ref_tot)  / (case_tot + ctrl_tot) >= 5
      AND   (case_tot * alt_tot)  / (case_tot + ctrl_tot) >= 5
      AND   (ctrl_tot * ref_tot)  / (case_tot + ctrl_tot) >= 5
      AND   (ctrl_tot * alt_tot)  / (case_tot + ctrl_tot) >= 5
),
chi2 AS (                                    -- Yates-corrected χ²
    SELECT  pos_start ,
            pos_end ,
            (
               POWER( ABS(a_ref_case * d_alt_ctrl - b_alt_case * c_ref_ctrl) 
                      - ( (case_tot + ctrl_tot) / 2.0 ) , 2 )
               * (case_tot + ctrl_tot)
            ) / NULLIF( (a_ref_case + b_alt_case)
                        * (c_ref_ctrl + d_alt_ctrl)
                        * (a_ref_case + c_ref_ctrl)
                        * (b_alt_case + d_alt_ctrl) , 0 )          AS chi_value
    FROM    filtered
)
SELECT  pos_start AS "start" ,
        pos_end   AS "end"   ,
        ROUND(chi_value, 4)  AS "chi_squared"
FROM    chi2
WHERE   chi_value >= 29.71679
ORDER BY chi_value DESC NULLS LAST;