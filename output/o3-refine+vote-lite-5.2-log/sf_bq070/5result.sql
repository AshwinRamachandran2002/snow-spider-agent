SELECT
    /* ---------- mandatory identifiers & links ---------- */
    "SeriesInstanceUID"                            AS "digital_slide_id",
    "StudyInstanceUID"                             AS "case_id",
    "ContainerIdentifier"                          AS "physical_slide_id",
    "PatientID"                                    AS "patient_id",
    "collection_id"                                AS "collection_id",
    "SOPInstanceUID"                               AS "instance_id",
    "gcs_url"                                      AS "gcs_url",

    /* ---------- image geometry ---------- */
    "Columns"                                      AS "width",
    "Rows"                                         AS "height",
    COALESCE("NominalScannedPixelSpacing",
             "PixelSpacing")                       AS "pixel_spacing",

    /* ---------- compression family ---------- */
    CASE
         WHEN "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.90',
                                      '1.2.840.10008.1.2.4.91')
              THEN 'jpeg2000'
         WHEN "TransferSyntaxUID" LIKE '1.2.840.10008.1.2.4.%'
              THEN 'jpeg'
         ELSE  'other'
    END                                            AS "compression_type",

    /* ---------- tissue label from specimen description ---------- */
    CASE
        WHEN POSITION('\"CodeValue\":\"17621005\"'
                      IN TO_VARCHAR("SpecimenDescriptionSequence")) > 0
             THEN 'normal'
        WHEN POSITION('\"CodeValue\":\"86049000\"'
                      IN TO_VARCHAR("SpecimenDescriptionSequence")) > 0
             THEN 'tumor'
    END                                            AS "tissue_type",

    /* ---------- cancer subtype from collection ---------- */
    CASE
        WHEN "collection_id" = 'tcga_luad' THEN 'luad'
        WHEN "collection_id" = 'tcga_lusc' THEN 'lscc'
    END                                            AS "cancer_subtype"

FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
      /* slide‑microscopy images from required collections */
      "collection_id"           IN ('tcga_luad','tcga_lusc')
  AND "Modality"                =  'SM'
  AND "VolumetricProperties"    =  'VOLUME'

      /* compression must be JPEG/JPEG2000 (exclude others) */
  AND "TransferSyntaxUID" LIKE '1.2.840.10008.1.2.4.%'
  AND "TransferSyntaxUID" NOT LIKE '1.2.840.10008.1.2.4.1%'   -- RLE etc.

      /* specimen embedding medium must be Tissue freezing medium */
  AND UPPER(TO_VARCHAR("SpecimenDescriptionSequence"))
          LIKE '%TISSUE FREEZING MEDIUM%'

      /* keep only slides that explicitly encode normal or tumor tissue */
  AND (
          POSITION('\"CodeValue\":\"17621005\"'
                   IN TO_VARCHAR("SpecimenDescriptionSequence")) > 0
       OR POSITION('\"CodeValue\":\"86049000\"'
                   IN TO_VARCHAR("SpecimenDescriptionSequence")) > 0
      )

ORDER BY
    "instance_id" ASC;