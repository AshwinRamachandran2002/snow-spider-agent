/*  Top‑10 samples with the largest number of loci that
    (1) contain exactly ONE alternate allele, and
    (2) have a homozygous‑reference genotype (0/0) for that sample           */

SELECT
       sample_id,
       COUNT(*) AS hom_ref_site_ct
FROM  (
        /* Explode the per‑variant, per‑sample call array                    */
        SELECT
               call_rec.VALUE:"name"::STRING          AS sample_id,
               call_rec.VALUE:"genotype"[0]::INT      AS g0,
               call_rec.VALUE:"genotype"[1]::INT      AS g1
        FROM   HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_VARIANTS_20150220   v,
               LATERAL FLATTEN( INPUT => v."call" )          call_rec
        /* Keep only variants with exactly one ALT allele                    */
        WHERE  ARRAY_SIZE( v."alternate_bases" ) = 1
      ) AS per_sample_variant
/* retain homozygous‑reference genotypes (0/0)                                */
WHERE  g0 = 0
  AND  g1 = 0
GROUP BY sample_id
ORDER BY hom_ref_site_ct DESC NULLS LAST
LIMIT 10;