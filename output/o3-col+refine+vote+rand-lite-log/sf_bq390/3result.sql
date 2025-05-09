SELECT DISTINCT
       d."StudyInstanceUID"
FROM   IDC.IDC_V17.DICOM_ALL        d
JOIN   IDC.IDC_V17.SEGMENTATIONS    s
       ON d."StudyInstanceUID" = s."StudyInstanceUID"
WHERE  d."collection_id" = 'qin_prostate_repeatability'
  AND  d."Modality"      = 'MR'
  -- T2-weighted axial MR series
  AND  (
          d."SeriesDescription" ILIKE '%t2%' 
       OR d."ImageType"        ILIKE '%t2%' 
       OR d."SequenceName"     ILIKE '%t2%'
      )
  AND  (
          d."SeriesDescription" ILIKE '%ax%' 
       OR d."SequenceName"     ILIKE '%ax%'
      )
  -- Segmentations labelled “Peripheral zone”
  AND  s."SegmentedPropertyType" ILIKE '%peripheral%zone%'
ORDER BY d."StudyInstanceUID";