WITH snp_calls AS (   -- 1. all SNP calls on chr X outside the two excluded regions
    SELECT
        c.value:"call_set_name"::STRING                    AS sample_id,
        c.value:"genotype"[0]::INTEGER                    AS g0,
        c.value:"genotype"[1]::INTEGER                    AS g1
    FROM "_1000_GENOMES"."_1000_GENOMES"."VARIANTS"  v,
         LATERAL FLATTEN( INPUT => v."call" )         c
    WHERE v."reference_name" = 'X'
      AND v."VT"              = 'SNP'
      AND NOT (v."start" BETWEEN  59999      AND  2699519)
      AND NOT (v."start" BETWEEN 154931042   AND 155260559)
      -- keep only rows that contain at least one allele
      AND (c.value:"genotype"[0] IS NOT NULL OR c.value:"genotype"[1] IS NOT NULL)
),
classified AS (        -- 2. classify each genotype call
    SELECT
        sample_id,

        /* homozygous reference: all observed alleles are 0 */
        CASE
            WHEN NVL(g0,0)=0 AND NVL(g1,0)=0
            THEN 1 ELSE 0
        END                                                   AS is_hom_ref,

        /* homozygous (or hemizygous) alternate:
           no reference allele present and all alt alleles identical          */
        CASE
            WHEN ( (g0 IS NULL OR g0 > 0) AND (g1 IS NULL OR g1 > 0) )   -- no ref allele
                 AND (g0 IS NULL OR g1 IS NULL OR g0 = g1)                -- identical if both present
            THEN 1 ELSE 0
        END                                                   AS is_hom_alt
    FROM snp_calls
),
aggregated AS (       -- 3. sum per sample
    SELECT
        sample_id,
        COUNT(*)                      AS callable_sites,
        SUM(is_hom_ref)               AS homo_ref_cnt,
        SUM(is_hom_alt)               AS homo_alt_cnt
    FROM classified
    GROUP BY sample_id
)

-- 4. final report
SELECT
    sample_id                                                             AS "Sample",
    callable_sites                                                        AS "Callable_Sites",
    homo_ref_cnt                                                          AS "Homozygous_Reference",
    homo_alt_cnt                                                          AS "Homozygous_Alternate",
    (callable_sites - homo_ref_cnt - homo_alt_cnt)                        AS "Heterozygous",
    (homo_alt_cnt + (callable_sites - homo_ref_cnt - homo_alt_cnt))       AS "SNV_Sites",
    ROUND( (callable_sites - homo_ref_cnt - homo_alt_cnt) * 100.0
           / NULLIF(homo_alt_cnt + (callable_sites - homo_ref_cnt - homo_alt_cnt),0)
           , 4)                                                           AS "Het_Percent_SNVs",
    ROUND( homo_alt_cnt * 100.0
           / NULLIF(homo_alt_cnt + (callable_sites - homo_ref_cnt - homo_alt_cnt),0)
           , 4)                                                           AS "HomAlt_Percent_SNVs"
FROM aggregated
ORDER BY "Het_Percent_SNVs" DESC NULLS LAST,
         "Sample";