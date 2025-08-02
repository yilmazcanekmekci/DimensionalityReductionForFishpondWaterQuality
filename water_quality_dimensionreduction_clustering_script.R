install.packages("corrplot")
install.packages("clusterSim")
install.packages("fpc")
install.packages("cluster")
install.packages("factoextra")
install.packages("Rtsne")
install.packages("umap")
install.packages("ggplot2")
install.packages("tseries")

library(corrplot)
library(clusterSim)
library(fpc)
library(cluster)
library(factoextra)
library(Rtsne)
library(umap)
library(ggplot2)
library(tseries)

#-------------------------------------------------------------------------------

# * Set working directory and load data

locationWD <- c("C:\\Users\\YILMAZ\\Desktop")
setwd(locationWD)
getwd()

# Read the dataset
data <- read.csv("WQD1.csv", header = TRUE)

#-------------------------------------------------------------------------------

# * Quality assessment

head(data)  
str(data)   
summary(data)  
dim(data)  

# Checking for missing data
missing_data <- data[!complete.cases(data),]

# Remove the 'Water.Quality' column 
data <- data[, !names(data) %in% "Water.Quality"]
head(data)

# Standardization
columns_to_standardize <- c("Temp", "Turbidity", "DO", "BOD", "CO2", 
                            "pH", "Alkalinity", "Hardness", "Calcium", 
                            "Ammonia", "Nitrite", "Phosphorus", "H2S", "Plankton")

data[columns_to_standardize] <- scale(data[columns_to_standardize])
head(data)

#-------------------------------------------------------------------------------

# * Test the structure of data

# Calculate the correlation matrix and visualize
cor_matrix <- cor(data[columns_to_standardize], method = "pearson")
print(cor_matrix, digits = 2)
corrplot(cor_matrix, order = "alphabet", tl.cex = 0.4)


# Principal Component Analysis (PCA)
pca_result <- prcomp(data[columns_to_standardize], center = TRUE, scale. = TRUE)
summary(pca_result)  # PCA summary

# Visualize cumulative variance explained by components
variance_explained <- summary(pca_result)$importance[3,]
plot(variance_explained, type = "l", main = "Cumulative Variance - PCA", 
     xlab = "Principal Components", ylab = "Cumulative Variance")


# Jarque-Bera Test for each numeric column
jarque_bera_results <- apply(data[columns_to_standardize], 2, function(column) {
  jarque.bera.test(column)$p.value
})

print(jarque_bera_results)

# Shapiro-Wilk Test for each numeric column
shapiro_results <- apply(data[columns_to_standardize], 2, function(column) {
  shapiro.test(column)$p.value
})

print(shapiro_results)

#-------------------------------------------------------------------------------

# * K-Means Clustering Without Dimensionality Reduction

# Determine the optimal number of clusters using Elbow Method
fviz_nbclust(data, kmeans, method = "wss") +
  ggtitle("Elbow Method for Optimal Clusters")

# Determine the optimal number of clusters using Silhouette Method
fviz_nbclust(data, kmeans, method = "silhouette") +
  ggtitle("Silhouette Method for Optimal Clusters")

# K-Means 
kmeans_result <- kmeans(data, centers = 3, nstart = 25)
data$cluster <- as.factor(kmeans_result$cluster)  # Add cluster labels to the dataset

# Evaluate clustering with metrics
silhouette_score <- silhouette(kmeans_result$cluster, dist(data[, columns_to_standardize]))
mean_silhouette <- mean(silhouette_score[, 3])
cat("Average Silhouette Score:", mean_silhouette, "\n")

davies_bouldin_index <- index.DB(data[, columns_to_standardize], kmeans_result$cluster)$DB
cat("Davies-Bouldin Index:", davies_bouldin_index, "\n")

calinski_harabasz_index <- calinhara(data[, columns_to_standardize], kmeans_result$cluster)
cat("Calinski-Harabasz Index:", calinski_harabasz_index, "\n")

#-------------------------------------------------------------------------------

# * K-Means Clustering Supported by t-SNE 

data_matrix <- as.matrix(data[columns_to_standardize])  # Prepare data for t-SNE
set.seed(42)  #reproducibility

# Apply t-SNE
tsne_result <- Rtsne(data_matrix, dims = 2, perplexity = 30, theta = 0.5, max_iter = 1000)
tsne_data <- data.frame(tsne_result$Y)
colnames(tsne_data) <- c("Dim1", "Dim2")

# Visualize t-SNE results
ggplot(tsne_data, aes(x = Dim1, y = Dim2)) +
  geom_point(alpha = 0.7, color = "lightblue") +
  labs(title = "Visualization with t-SNE", x = "Dimension 1", y = "Dimension 2") +
  theme_minimal()

fviz_nbclust(tsne_data, kmeans, method = "wss") +
  ggtitle("Elbow Method for Optimal Clusters")

fviz_nbclust(tsne_data, kmeans, method = "silhouette") +
  ggtitle("Silhouette Method for Optimal Clusters")

kmeans_result_tsne <- kmeans(tsne_data, centers = 3, nstart = 25)
tsne_data$cluster <- as.factor(kmeans_result_tsne$cluster)

# Visualize clustering results
fviz_cluster(kmeans_result_tsne, data = tsne_data[, 1:2],
             geom = "point", ellipse.type = "convex", palette = "jco",
             ggtheme = theme_minimal()) +
  ggtitle("K-Means Clustering with t-SNE")

# Evaluate clustering
silhouette_score_tsne <- silhouette(kmeans_result_tsne$cluster, dist(tsne_data[, 1:2]))
mean_silhouette_tsne <- mean(silhouette_score_tsne[, 3])
cat("Average Silhouette Score (t-SNE):", mean_silhouette_tsne, "\n")

davies_bouldin_index_tsne <- index.DB(tsne_data[, 1:2], kmeans_result_tsne$cluster)$DB
cat("Davies-Bouldin Index (t-SNE):", davies_bouldin_index_tsne, "\n")

calinski_harabasz_index_tsne <- calinhara(tsne_data[, 1:2], kmeans_result_tsne$cluster)
cat("Calinski-Harabasz Index (t-SNE):", calinski_harabasz_index_tsne, "\n")

#-------------------------------------------------------------------------------

# * UMAP Based K-Means Clustering

# Apply UMAP
umap_config <- umap.defaults
umap_config$n_neighbors <- 10
umap_config$min_dist <- 0.1
umap_config$metric <- "euclidean"

umap_result <- umap(data_matrix, config = umap_config)
umap_data <- as.data.frame(umap_result$layout)
colnames(umap_data) <- c("Dim1", "Dim2")

# Visualize UMAP results
ggplot(umap_data, aes(x = Dim1, y = Dim2)) +
  geom_point(alpha = 0.7, color = "lightgreen") +
  labs(title = "Visualization with UMAP", x = "Dimension 1", y = "Dimension 2") +
  theme_minimal()

fviz_nbclust(umap_data, kmeans, method = "wss") +
  ggtitle("Elbow Method for Optimal Clusters")

fviz_nbclust(umap_data, kmeans, method = "silhouette") +
  ggtitle("Silhouette Method for Optimal Clusters")

kmeans_result_umap <- kmeans(umap_data, centers = 3, nstart = 25)
umap_data$cluster <- as.factor(kmeans_result_umap$cluster)

# Visualize clustering results
fviz_cluster(kmeans_result_umap, data = umap_data[, 1:2],
             geom = "point", ellipse.type = "convex", palette = "jco",
             ggtheme = theme_minimal()) +
  ggtitle("K-Means Clustering with UMAP")

# Evaluate clustering
silhouette_score_umap <- silhouette(kmeans_result_umap$cluster, dist(umap_data[, 1:2]))
mean_silhouette_umap <- mean(silhouette_score_umap[, 3])
cat("Average Silhouette Score (UMAP):", mean_silhouette_umap, "\n")

davies_bouldin_index_umap <- index.DB(umap_data[, 1:2], kmeans_result_umap$cluster)$DB
cat("Davies-Bouldin Index (UMAP):", davies_bouldin_index_umap, "\n")

calinski_harabasz_index_umap <- calinhara(umap_data[, 1:2], kmeans_result_umap$cluster)
cat("Calinski-Harabasz Index (UMAP):", calinski_harabasz_index_umap, "\n")

#-------------------------------------------------------------------------------

# * Detection and Removal of Outliers and Applying UMAP and K-Means

detect_outliers <- function(column) {
  Q1 <- quantile(column, 0.25, na.rm = TRUE)
  Q3 <- quantile(column, 0.75, na.rm = TRUE)
  IQR_value <- Q3 - Q1
  lower_bound <- Q1 - 1.5 * IQR_value
  upper_bound <- Q3 + 1.5 * IQR_value
  outliers <- column[column < lower_bound | column > upper_bound]
  return(outliers)
}

# Remove outliers 
cleaned_data <- data
for (column in columns_to_standardize) {
  outliers <- detect_outliers(cleaned_data[[column]])
  cleaned_data <- cleaned_data[!cleaned_data[[column]] %in% outliers, ]
}

original_row_count <- nrow(data)
cleaned_row_count <- nrow(cleaned_data)
removed_row_count <- original_row_count - cleaned_row_count
data_distribution <- c(Cleaned = cleaned_row_count, Removed = removed_row_count)

# Draw a pie chart
pie(data_distribution,
    labels = c(paste("(", round((cleaned_row_count / original_row_count) * 100, 2), "%)", sep = ""),
               paste("Removed (", round((removed_row_count / original_row_count) * 100, 2), "%)", sep = "")),
    col = c("skyblue", "tomato"),
    main = "Data Distribution After Outlier Removal")


# Apply UMAP
umap_config <- umap.defaults
umap_config$n_neighbors <- 10
umap_config$min_dist <- 0.1
umap_config$metric <- "euclidean"

head(cleaned_data)
dim(cleaned_data)

cleaned_data <- cleaned_data[, !colnames(cleaned_data) %in% "cluster"]

numeric_columns <- sapply(cleaned_data, is.numeric) 
data_matrix <- as.matrix(cleaned_data[, numeric_columns])  

umap_result <- umap(data_matrix, config = umap_config)

umap_data <- as.data.frame(umap_result$layout)
colnames(umap_data) <- c("Dim1", "Dim2")

# Visualize UMAP results
ggplot(umap_data, aes(x = Dim1, y = Dim2)) +
  geom_point(alpha = 0.7, color = "lightpink") +
  labs(title = "Visualization with UMAP (Outliers Removed)", x = "Dimension 1", y = "Dimension 2") +
  theme_minimal()

fviz_nbclust(umap_data, kmeans, method = "wss") +
  ggtitle("Elbow Method for Optimal Clusters (Outliers Removed)")

fviz_nbclust(umap_data, kmeans, method = "silhouette") +
  ggtitle("Silhouette Method for Optimal Clusters (Outliers Removed)")

# K-Means Clustering
optimal_clusters <- 3  
kmeans_result_umap <- kmeans(umap_data, centers = optimal_clusters, nstart = 25)
umap_data$cluster <- as.factor(kmeans_result_umap$cluster)

# Visualize clustering results
fviz_cluster(kmeans_result_umap, data = umap_data[, 1:2],
             geom = "point", ellipse.type = "convex", palette = "jco",
             ggtheme = theme_minimal()) +
  ggtitle("K-Means Clustering with UMAP (Outliers Removed)")

# Evaluate cluster results
silhouette_score_umap <- silhouette(kmeans_result_umap$cluster, dist(umap_data[, 1:2]))
mean_silhouette_umap <- mean(silhouette_score_umap[, 3])
cat("Average Silhouette Score (UMAP without outliers):", mean_silhouette_umap, "\n")

davies_bouldin_index_umap <- index.DB(umap_data[, 1:2], kmeans_result_umap$cluster)$DB
cat("Davies-Bouldin Index (UMAP without outliers):", davies_bouldin_index_umap, "\n")

calinski_harabasz_index_umap <- calinhara(umap_data[, 1:2], kmeans_result_umap$cluster)
cat("Calinski-Harabasz Index (UMAP without outliers):", calinski_harabasz_index_umap, "\n")

#-------------------------------------------------------------------------------


