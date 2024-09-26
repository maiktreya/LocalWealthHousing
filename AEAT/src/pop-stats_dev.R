# Obtain population statistics for AEAT subsample

# Clean environment to avoid RAM bottlenecks and import dependencies

rm(list = ls())
library(data.table)
library(survey)
library(magrittr)
library(dineq)
source("AEAT/src/transform/etl_pipe.R")

# Import needed data objects

age <- fread("AEAT/data/madrid-age.csv")
sex <- fread("AEAT/data/madrid-sex.csv")



########################################################
# Example age vector (replace this with your actual data)
age_vector <- c(1, 8, 23, 37, 42, 67, 85, 100)

# Define age breaks based on your ranges
age_breaks <- seq(0, 100, by = 5)

# Add an extra value for 100+ category
age_breaks <- c(age_breaks, Inf)

# Define labels for the age categories
age_labels <- c("De 0 a 4 años", "De 5 a 9 años", "De 10 a 14 años",
                "De 15 a 19 años", "De 20 a 24 años", "De 25 a 29 años",
                "De 30 a 34 años", "De 35 a 39 años", "De 40 a 44 años",
                "De 45 a 49 años", "De 50 a 54 años", "De 55 a 59 años",
                "De 60 a 64 años", "De 65 a 69 años", "De 70 a 74 años",
                "De 75 a 79 años", "De 80 a 84 años", "De 85 a 89 años",
                "De 90 a 94 años", "De 95 a 99 años", "100 y más años")

# Use cut to categorize ages based on the breaks
age_categories <- cut(age_vector, breaks = age_breaks, labels = age_labels, right = FALSE)

# Display the categorized ages
print(age_categories)
