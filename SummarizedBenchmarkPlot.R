fxx <- dir("logs", recursive = TRUE, full.names = TRUE)

rellogs <- grep("FragPipe",fxx, value = TRUE)

runtime_DEA <- function(log_file) {
  datafLOG <- read.table(log_file, header = TRUE, sep = "", fill = TRUE,
                         comment.char = "", check.names = FALSE,
                         skip = 0)
  datafLOG <- datafLOG[!grepl("^%CPU", datafLOG$`%CPU`), ]
  datafLOG <- datafLOG[-nrow(datafLOG),]
  datafLOG$TIME  <- as.numeric(lubridate::hms(datafLOG$TIME))
  datafLOG$GB <- as.numeric(datafLOG$RSS)/(1024*1024)
  res <- list(data = datafLOG, maxGB = max(datafLOG$GB),
              maxTime = max(datafLOG$TIME) / 60)
  return(res)
}

xx <- lapply(rellogs,runtime_DEA)
xx

GB <- sapply(rellogs,function(x){runtime_DEA(x)$maxGB})
Time <- sapply(rellogs,function(x){runtime_DEA(x)$maxTime})

x <- data.frame(names = names(GB), names2 = names(Time), GB, Time)
rownames(x) <- NULL
all(x$names == x$names2)
x$names2 <- NULL
x <- x |> tidyr::separate("names", c(NA, "folder", "log"), remove = FALSE, sep = "/")

x$app <- gsub("^prolfqua_logMemUsage_","", x$log)

x$app <- gsub("\\.log$","", x$app)

filesizes <- read.delim("logs/reportfile_sizes.txt", sep = " ", header = FALSE)
filesizes$V2 <- NULL

colnames(filesizes) <- c("MB","folder")

filesizes <- filesizes |> tidyr::separate(folder, c(NA,"folder", NA), sep = "/")
filesizes$folder %in% x$folder
x$folder %in% filesizes$folder
benchresults <- dplyr::inner_join(filesizes, x)
benchresults$names <- NULL
benchresults$log <- NULL


benchresultsPEP <- benchresults[c(7,5),]
benchresultsPEP$nrModels <- c(94587, 8624)
benchresultsPEP$app<- c("peptide", "protein")
benchresultsPEP$app <- paste0(benchresultsPEP$app, "(#",  benchresultsPEP$nrModels, ")")
benchresultsPEP$app <- factor(benchresultsPEP$app, levels = c(benchresultsPEP$app[2], benchresultsPEP$app[1]))

####
library(ggplot2)

# Create the data frame

# Barplot for GB
plot_GB <- ggplot(benchresultsPEP, aes(x = app, y = GB)) +
  geom_bar(stat = "identity") +
  labs(x = "Protein/Peptide", y = "Memory usage [GB]", tag= "C") +
  theme_minimal()

# Barplot for Time
plot_Time <- ggplot(benchresultsPEP, aes(x = app, y = Time)) +
  geom_bar(stat = "identity") +
  labs(x = "Protein/Peptide", y = "Time [min]", tag = "D") +
  theme_minimal()


# Combine the plots with labels
labeled_plots <- cowplot::plot_grid(
  plot_Time, plot_GB,
  ncol = 2
)
ggsave("protein_vs_peptide.pdf", labeled_plots )

#####
benchresultsProt <- benchresults[-7,]
bnechresultsDIANN <- benchresultsProt |> dplyr::filter(!grepl("msstats",folder))

bnechresultsDIANN$nrSamples <-  gsub(".*_f([0-9]+)_.*", "\\1", bnechresultsDIANN$folder) |> as.integer()
bnechresultsDIANN$app <- gsub("dea_[1-2]","dea", bnechresultsDIANN$app)


library(ggplot2)

# Plotting
f1 <- ggplot(bnechresultsDIANN, aes(x = nrSamples, y = Time, color = app, group = app)) +
  geom_line() +
  geom_point() +
  labs(
    x = "nr Samples",
    y = "Time [min]",
    color = "Application",
    tag = "A"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5)
  )

# Plotting
f2 <- ggplot(bnechresultsDIANN, aes(x = MB/1024, y = GB, color = app, group = app)) +
  geom_line() +
  geom_point() +
  labs(
    x = "File Size [GB]",
    y = "Memory usage [GB]",
    color = "Application",
    tag = "B"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5)
  )

library(patchwork)
gg <- f1 + f2 + patchwork::plot_layout(ncol = 2, guides = "collect") & theme(legend.position = "bottom")
print(gg)
ggsave("performance.pdf", gg )

# Combine the plots with labels
xtest <- cowplot::plot_grid(
  gg, labeled_plots, ncol=1
)
ggsave("allplots.pdf", xtest)
