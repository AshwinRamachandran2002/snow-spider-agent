/* -------------------------------------------------------------
   Top-11 cytobands on chromosome 1 for each CNV category
   in kidney-cancer projects (all “TCGA-KI%”, which includes
   TCGA-KIRC) using the highest available copy-number value.

       • Amplification :  > 3 copies
       • Gain          :  = 3 copies
       • HetDeletion   :  = 1 copy
--------------------------------------------------------------*/
WITH gene2band AS (   -- map every gene‐level CNV record to the cytobands it overlaps
    SELECT
        c."cytoband_name",
        COALESCE(g."max_copy_number", g."copy_number") AS cn
    FROM   "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_GENE_LEVEL_HG38_GDC_R36"  g
    JOIN   "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"                                 c
           ON  g."chromosome" = c."chromosome"
           AND g."start_pos"  <= c."hg38_stop"
           AND g."end_pos"    >= c."hg38_start"
    WHERE  g."project_short_name" ILIKE 'TCGA-KI%'    -- covers KIRC / KICH / KIRP
      AND  g."chromosome"         = 'chr1'
      AND  COALESCE(g."max_copy_number", g."copy_number") IS NOT NULL
), band_counts AS (  -- count events by cytoband & alteration class
    SELECT
        "cytoband_name",
        CASE
            WHEN cn > 3 THEN 'Amplification'
            WHEN cn = 3 THEN 'Gain'
            WHEN cn = 1 THEN 'HetDeletion'
        END AS alteration,
        COUNT(*) AS events
    FROM   gene2band
    WHERE  (cn = 1 OR cn = 3 OR cn > 3)
    GROUP  BY "cytoband_name", alteration
), ranked AS (       -- rank within each alteration class
    SELECT
        "cytoband_name",
        alteration,
        events,
        ROW_NUMBER() OVER (PARTITION BY alteration
                           ORDER BY events DESC NULLS LAST) AS rn
    FROM band_counts
)
SELECT
    "cytoband_name",
    alteration,
    events
FROM   ranked
WHERE  rn <= 11
ORDER  BY alteration,
         events DESC NULLS LAST;