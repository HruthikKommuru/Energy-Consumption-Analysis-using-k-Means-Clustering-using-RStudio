

library(ggplot2)
library(lubridate)
library(dplyr)
library(tidyr)
library(DT)
library(scales)
########################## 1. DATA PREPARATION ##################

# Read the data with semicolon as the delimiter
power <- read.csv("/Users/hruthikkommuru/Desktop/Data Mining/Project/Datasets/Project Set7_Datasets/Group14_household_power_consumption.txt", sep = ";", header = FALSE, stringsAsFactors = FALSE)
# Providing column names
colnames(power) <- c("Date", "Time", "Global_active_power", "Global_reactive_power", "Voltage", "Global_intensity", "Sub_metering_1", "Sub_metering_2", "Sub_metering_3")
View(power)
###################### Cleaning the data #####################
# checking the missing values in the whole data
sum(is.na(power))
# removing the missing values because the whole of missing values is of 5% of the data
power <- na.omit(power)
sum(is.na(power))
dim(power)
power <- power[-c(1),]
str(power)

###################### Transforming the data and Normalizing ###################

# Converting relevant columns to numeric
power[, 3:9] <- lapply(power[, 3:9], as.numeric)
# Checking for NAs again and handleing them if needed
sum(is.na(power))  # Check for NAs
power <- na.omit(power) # removing NAs
# Perform normalization 
power[, 3:9] <- scale(power[, 3:9])

###################### converting into date and time format  ###################

head(power[,1:2])

power$Date.Time <- as.POSIXct(paste(power$Date, power$Time), format = "%d/%m/%Y %H:%M:%S")
power$Date <- format(power$Date.Time, format = "%d/%m/%Y")
power$Time <- format(power$Date.Time, format = "%H:%M:%S")
power$day <- factor(day(power$Date.Time)) #adding day column and adding the day
power$month <- factor(month(power$Date.Time, label = TRUE))#adding month column and adding the month
power$year <- factor(year(power$Date.Time))
power$dayofweek <- factor(wday(power$Date.Time, label = TRUE))
power$hour <- factor(hour(hms(power$Time)))#adding hour column and adding the hour
power$minute <- factor(minute(hms(power$Time)))#adding minute column and adding the minute
power$second <- factor(second(hms(power$Time)))
View(power)
power <- power[, -which(names(power) %in% c("Date.Time"))]
head(power)
str(power)


set.seed(1)
rmse <- numeric(10) #rmse value will be computed and stored in in this variable
#columns we want to consider while performing k means
selected_features <- power[, c("Global_active_power", "Global_reactive_power", "Voltage", "Global_intensity", "Sub_metering_1", "Sub_metering_2", "Sub_metering_3")]

#finding the optimal k value for k means clustering

for (k in 1:10) {
  num_clusters <- k 
  model <- kmeans(selected_features, centers = num_clusters)
  rmse[k] <- sqrt(model$tot.withinss / model$totss)
}

rmse

plot(1:10, rmse, type="b", xlab="Number of Clusters", ylab="Root Mean Square Error")

#Identify the Optimal Number of Clusters: Look for a point where the RMSE value starts to decrease at a slower rate.
##### Building K Means using K=6 ##

# Selecting relevant features for clustering
selected_features <- power[, c("Global_active_power", "Global_reactive_power", "Voltage", "Global_intensity", "Sub_metering_1", "Sub_metering_2", "Sub_metering_3")]

# Perform k-Means clustering with, 6 clusters
num_clusters <- 6 
kmeans_model <- kmeans(selected_features, centers = num_clusters)
kmeans_model$cluster

kmeans_model$centers #getting the cluster centroids
dist(kmeans_model$centers) #distance between the centers

# Extracting and viewing cluster centroids
centroids <- kmeans_model$centers
print(centroids)
table(kmeans_model$cluster) #how data is distributed over different clusters

# Plotting the centroids for comparison
centroid_df <- as.data.frame(centroids)
centroid_df$cluster <- 1:nrow(centroid_df)
long_centroids <- gather(centroid_df, key = "feature", value = "value", -cluster)
#using ggplot for visualization
ggplot(long_centroids, aes(x = feature, y = value, fill = factor(cluster))) +
  geom_bar(stat = "identity", position = position_dodge()) +
  theme_minimal() +
  labs(title = "Comparison of Cluster Centroids", x = "Feature", y = "Value", fill = "Cluster")

# Assuming 'power' dataframe has time variables  'year', 'month'
power$cluster <- kmeans_model$cluster

# Plotting clusters over time
ggplot(power, aes(x = year, fill = factor(cluster))) +
  geom_bar(position = "dodge") +
  theme_minimal() +
  labs(title = "Cluster Distribution Over Years", x = "Year", y = "Count", fill = "Cluster")


# Perform PCA for visualization 
pca_result <- prcomp(selected_features, scale. = TRUE)
pca_data <- data.frame(pca_result$x[,1:2])
# Add cluster information
pca_data$cluster <- kmeans_model$cluster
plot(pca_data$PC1, pca_data$PC2, col=pca_data$cluster)

#cluster wise  box plot for each element
#boxplot for global active power
ggplot(power, aes(x = factor(cluster), y = Global_active_power)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Box Plot of Global Active Power by Cluster", x = "Cluster", y = "Global Active Power")
#boxplot for global reactive power
ggplot(power, aes(x = factor(cluster), y = Global_reactive_power)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Box Plot of Global Reactive Power by Cluster", x = "Cluster", y = "Global Reactivee Power")
#boxplot for global intensity
ggplot(power, aes(x = factor(cluster), y = Global_intensity)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Box Plot of Global intensity by Cluster", x = "Cluster", y = "Global Intensity")





