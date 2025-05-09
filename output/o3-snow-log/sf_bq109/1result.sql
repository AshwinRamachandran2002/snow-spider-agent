WITH "filtered" AS (
    SELECT *
    FROM OPEN_TARGETS_GENETICS_1.GENETICS."VARIANT_DISEASE_COLOC"
    WHERE "right_gene_id"      = 'ENSG00000169174'
      AND "coloc_h4"           > 0.8
      AND "coloc_h3"           < 0.02
      AND "right_bio_feature"  = 'IPSC'
      AND (   ( "left_chrom"  = '1' AND "left_pos"  = 55029009 
                AND "left_ref" = 'C' AND "left_alt" = 'T')
           OR ( "right_chrom" = '1' AND "right_pos" = 55029009 
                AND "right_ref" = 'C' AND "right_alt" = 'T')
          )
),
"stats" AS (   -- average, variance, range and the max value itself
    SELECT  AVG("coloc_log2_h4_h3")                          AS "avg_val",
            VAR_SAMP("coloc_log2_h4_h3")                     AS "var_val",
            MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3") AS "range_val",
            MAX("coloc_log2_h4_h3")                          AS "max_val"
    FROM    "filtered"
),
"max_study" AS (     -- right study (QTL source) for the maximum log2(h4/h3)
    SELECT  "right_study"
    FROM    "filtered" f
            JOIN "stats" s
              ON f."coloc_log2_h4_h3" = s."max_val"
    LIMIT 1                       -- if multiple, take any one
)
SELECT  s."avg_val"      AS "average_log2_h4_h3",
        s."var_val"      AS "variance_log2_h4_h3",
        s."range_val"    AS "max_min_difference_log2_h4_h3",
        m."right_study"  AS "qtl_source_of_max_log2_h4_h3"
FROM    "stats" s,
        "max_study" m;