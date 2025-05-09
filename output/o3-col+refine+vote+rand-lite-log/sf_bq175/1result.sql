WITH joined AS (   -- map allelic CNV segments on chr1 to cytobands
    SELECT
        cb."cytoband_name",
        CASE
            WHEN s."copy_number" >= 4 THEN 'Amplification'
            WHEN s."copy_number"  = 3 THEN 'Gain'
            WHEN s."copy_number"  = 1 THEN 'Heterozygous Deletion'
        END AS "category"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                      cb
      ON  cb."chromosome" = s."chromosome"
      AND GREATEST(s."start_pos", cb."hg38_start")
          <= LEAST(s."end_pos",  cb."hg38_stop")         -- interval overlap
    WHERE s."chromosome" = 'chr1'                        -- chromosome 1 only
      AND s."copy_number" IN (1,3,4,5,6,7,8,9)           -- keep relevant CNV events
), ranked AS (        -- count & rank cytobands within each CNV category
    SELECT
        "cytoband_name",
        "category",
        COUNT(*) AS cnt,
        RANK() OVER (PARTITION BY "category"
                     ORDER BY COUNT(*) DESC NULLS LAST) AS rnk
    FROM joined
    WHERE "category" IS NOT NULL
    GROUP BY "cytoband_name", "category"
)
SELECT
    "cytoband_name"
FROM ranked
WHERE rnk <= 11                    -- top-11 per CNV category
GROUP BY "cytoband_name"
HAVING COUNT(DISTINCT "category") = 3  -- appears in all three categories
ORDER BY "cytoband_name";