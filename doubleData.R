alld <- readr::read_tsv("FragPipe_f187_diann/report.tsv")
alld2 <- alld
alld2$Run <- paste0(alld2$Run, "_V2")
dd <- unique(alld2$File.Name)
alld2$File.Name <- gsub("\\.mzML", "_V2\\.mzML", alld2$File.Name)
alldx <- dplyr::bind_rows(alld, alld2)
readr::write_tsv(alldx, "FragPipe_f374_diann/x2_report.tsv")


alld3 <- alld
alld3$Run <- paste0(alld3$Run, "_V3")
alld3$File.Name <- gsub("\\.mzML", "_V3\\.mzML", alld3$File.Name)
alld <- dplyr::bind_rows(alldx, alld3)
dir.create("FragPipe_f561_diann")
readr::write_tsv(alld, "FragPipe_f561_diann/x3_report.tsv")
